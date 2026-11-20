BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $caminhoDoRelay = Join-Path $TestDrive 'relay-de-rede.exe'
    InModuleScope WinPlaybook -Parameters @{ Caminho = $caminhoDoRelay } { New-ExecutavelDoRelayDeRede -Caminho $Caminho }

    function Start-RelayDeRede {
        <#
        .SYNOPSIS
        Inicia o relay de rede com os argumentos escolhidos, com a entrada vazia e as saídas gravadas em arquivos, e devolve o processo e os arquivos.

        .PARAMETER Argumentos
        Os argumentos do relay, como 'conectar 8080'.

        .EXAMPLE
        $relay = Start-RelayDeRede -Argumentos "conectar $porta"
        #>
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param(
            [Parameter(Mandatory)] [string] $Argumentos
        )

        $pasta = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $pasta
        $entrada = Join-Path $pasta 'entrada.txt'
        [IO.File]::WriteAllText($entrada, '')
        $saida = Join-Path $pasta 'saida.txt'
        $erros = Join-Path $pasta 'erros.txt'
        $processo = Start-Process -FilePath $caminhoDoRelay -ArgumentList $Argumentos -RedirectStandardInput $entrada -RedirectStandardOutput $saida -RedirectStandardError $erros -NoNewWindow -PassThru
        $null = $processo.Handle
        return [pscustomobject]@{ Processo = $processo; Saida = $saida; Erros = $erros }
    }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Relay de rede' {
    BeforeAll {
        $escuta = New-Object System.Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0)
        $escuta.Start()
        $porta = $escuta.LocalEndpoint.Port
    }

    AfterAll {
        $escuta.Stop()
    }

    Context 'quando conecta numa porta em que o Windows escuta' {
        BeforeAll {
            $relay = Start-RelayDeRede -Argumentos "conectar $porta"
            $aceite = $escuta.AcceptTcpClientAsync()
            $null = $aceite.Wait(10000)
            $cliente = $aceite.Result
            $dados = [Text.Encoding]::ASCII.GetBytes("oi do servidor`n")
            $cliente.GetStream().Write($dados, 0, $dados.Length)
            $cliente.Close()
            $saiuSozinho = $relay.Processo.WaitForExit(10000)
        }

        AfterAll {
            $relay.Processo.Dispose()
        }

        It 'repassa à saída o que o serviço responde' {
            [IO.File]::ReadAllText($relay.Saida).Trim() | Should-Be 'oi do servidor'
        }

        It 'sai com 0 quando a entrada termina' {
            $saiuSozinho | Should-BeTrue
            $relay.Processo.ExitCode | Should-Be 0
        }
    }

    Context 'quando conecta num endereço de destino' {
        BeforeAll {
            $enderecoDaMaquina = [Net.Dns]::GetHostAddresses([Net.Dns]::GetHostName()) | Where-Object { $_.AddressFamily -eq 'InterNetwork' -and -not [Net.IPAddress]::IsLoopback($_) } | Select-Object -First 1
            $destino = New-Object System.Net.Sockets.TcpListener ($enderecoDaMaquina, 0)
            $destino.Start()
            $relay = Start-RelayDeRede -Argumentos "conectar $($destino.LocalEndpoint.Port) $enderecoDaMaquina"
            $aceite = $destino.AcceptTcpClientAsync()
            $conectou = $aceite.Wait(10000)
            if ($conectou) {
                $dados = [Text.Encoding]::ASCII.GetBytes("oi do destino`n")
                $aceite.Result.GetStream().Write($dados, 0, $dados.Length)
                $aceite.Result.Close()
            }
            $null = $relay.Processo.WaitForExit(10000)
        }

        AfterAll {
            $destino.Stop()
            if (-not $relay.Processo.HasExited) {
                $relay.Processo.Kill()
            }
            $relay.Processo.Dispose()
        }

        It 'conecta no endereço pedido, e não no localhost' {
            $conectou | Should-BeTrue
        }

        It 'repassa à saída o que o destino responde' {
            [IO.File]::ReadAllText($relay.Saida).Trim() | Should-Be 'oi do destino'
        }
    }

    Context 'quando <Descricao> recusa a conexão' -ForEach @(
        @{ Descricao = 'o localhost do Windows'; Destino = '' }
        @{ Descricao = 'o endereço de destino'; Destino = ' 127.0.0.1' }
    ) {
        BeforeAll {
            $portaFechada = New-Object System.Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0)
            $portaFechada.Start()
            $numeroDaPortaFechada = $portaFechada.LocalEndpoint.Port
            $portaFechada.Stop()
            $relay = Start-RelayDeRede -Argumentos "conectar $numeroDaPortaFechada$Destino"
            $null = $relay.Processo.WaitForExit(10000)
        }

        AfterAll {
            $relay.Processo.Dispose()
        }

        It 'sai com 1 e explica o erro' {
            $relay.Processo.ExitCode | Should-Be 1
            [IO.File]::ReadAllText($relay.Erros) | Should-BeLikeString 'WinPlaybook:*'
        }
    }

    Context 'quando lista as portas' {
        BeforeAll {
            $informacoes = [Diagnostics.ProcessStartInfo]::new($caminhoDoRelay, 'portas')
            $informacoes.UseShellExecute = $false
            $informacoes.RedirectStandardInput = $true
            $informacoes.RedirectStandardOutput = $true
            $relay = [Diagnostics.Process]::Start($informacoes)
            $leitura = $relay.StandardOutput.ReadLineAsync()
            $null = $leitura.Wait(10000)
            $lista = $leitura.Result
            $relayContinuaComAEntradaAberta = -not $relay.WaitForExit(2000)
            $relay.StandardInput.Close()
            $relaySaiuNoFimDaEntrada = $relay.WaitForExit(10000)
        }

        AfterAll {
            if (-not $relay.HasExited) {
                $relay.Kill()
            }
            $relay.Dispose()
        }

        It 'inclui a porta em que o teste escuta' {
            @("$lista" -split ' ') | Should-ContainCollection "$porta"
        }

        It 'continua rodando enquanto a entrada está aberta' {
            $relayContinuaComAEntradaAberta | Should-BeTrue
        }

        It 'termina quando a entrada fecha' {
            $relaySaiuNoFimDaEntrada | Should-BeTrue
        }
    }
}
