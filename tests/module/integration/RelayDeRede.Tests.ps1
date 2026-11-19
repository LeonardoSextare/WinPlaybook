BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $caminhoDoRelay = Join-Path $TestDrive 'relay-de-rede.exe'
    InModuleScope WinPlaybook -Parameters @{ Caminho = $caminhoDoRelay } { New-ExecutavelDoRelayDeRede -Caminho $Caminho }

    function Start-RelayDeRede {
        <#
        .SYNOPSIS
        Inicia o relay de rede com os argumentos escolhidos, com a entrada e as saídas redirecionadas, e devolve o processo.

        .PARAMETER Argumentos
        Os argumentos do relay, como 'portas' ou 'conectar 8080'.

        .EXAMPLE
        $relay = Start-RelayDeRede -Argumentos "conectar $porta"
        #>
        [CmdletBinding()]
        [OutputType([Diagnostics.Process])]
        param(
            [Parameter(Mandatory)] [string] $Argumentos
        )

        $inicio = New-Object Diagnostics.ProcessStartInfo($caminhoDoRelay, $Argumentos)
        $inicio.UseShellExecute = $false
        $inicio.RedirectStandardInput = $true
        $inicio.RedirectStandardOutput = $true
        $inicio.RedirectStandardError = $true
        return [Diagnostics.Process]::Start($inicio)
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
            $linha = $relay.StandardOutput.ReadLine()
            $relay.StandardInput.Close()
            $saiuSozinho = $relay.WaitForExit(10000)
        }

        AfterAll {
            $relay.Dispose()
        }

        It 'repassa à saída o que o serviço responde' {
            $linha | Should-Be 'oi do servidor'
        }

        It 'sai com 0 quando a entrada termina' {
            $saiuSozinho | Should-BeTrue
            $relay.ExitCode | Should-Be 0
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
        }

        AfterAll {
            if ($conectou) {
                $aceite.Result.Close()
            }
            $destino.Stop()
            if (-not $relay.HasExited) {
                $relay.Kill()
            }
            $relay.Dispose()
        }

        It 'conecta no endereço pedido, e não no localhost' {
            $conectou | Should-BeTrue
        }
    }

    Context 'quando o endereço de destino recusa a conexão' {
        BeforeAll {
            $portaFechada = New-Object System.Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0)
            $portaFechada.Start()
            $numeroDaPortaFechada = $portaFechada.LocalEndpoint.Port
            $portaFechada.Stop()
            $relay = Start-RelayDeRede -Argumentos "conectar $numeroDaPortaFechada 127.0.0.1"
            $erros = $relay.StandardError.ReadToEnd()
            $null = $relay.WaitForExit(10000)
        }

        AfterAll {
            $relay.Dispose()
        }

        It 'sai com 1 e explica o erro' {
            $relay.ExitCode | Should-Be 1
            $erros | Should-BeLikeString 'WinPlaybook:*'
        }
    }

    Context 'quando conecta numa porta em que o Windows não escuta' {
        BeforeAll {
            $portaFechada = New-Object System.Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0)
            $portaFechada.Start()
            $numeroDaPortaFechada = $portaFechada.LocalEndpoint.Port
            $portaFechada.Stop()
            $relay = Start-RelayDeRede -Argumentos "conectar $numeroDaPortaFechada"
            $erros = $relay.StandardError.ReadToEnd()
            $null = $relay.WaitForExit(10000)
        }

        AfterAll {
            $relay.Dispose()
        }

        It 'sai com 1 e explica o erro' {
            $relay.ExitCode | Should-Be 1
            $erros | Should-BeLikeString 'WinPlaybook:*'
        }
    }

    Context 'quando lista as portas' {
        BeforeAll {
            $relay = Start-RelayDeRede -Argumentos 'portas'
            $leitura = $relay.StandardOutput.ReadLineAsync()
            $null = $leitura.Wait(10000)
            $relay.Kill()
            $null = $relay.WaitForExit(5000)
        }

        AfterAll {
            $relay.Dispose()
        }

        It 'inclui a porta em que o teste escuta' {
            @($leitura.Result -split ' ') | Should-ContainCollection "$porta"
        }
    }
}
