BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/AgenteSsh.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $caminhoDoRelay = Join-Path $TestDrive 'relay-do-agente-ssh.exe'
    InModuleScope WinPlaybook -Parameters @{ Caminho = $caminhoDoRelay } { New-ExecutavelDoRelay -Caminho $Caminho }

    function Start-Relay {
        <#
        .SYNOPSIS
        Inicia o relay com o pipe escolhido, com a entrada e as saídas redirecionadas, e devolve o processo.

        .DESCRIPTION
        No Windows PowerShell 5.1, a entrada do processo usa a codificação da entrada do console,
        que escreve um BOM antes do primeiro byte quando é UTF-8. Durante o início do processo, a
        codificação fica em UTF-8 sem BOM, para o relay receber só os bytes do teste.

        .PARAMETER Pipe
        O nome do named pipe que o relay recebe.

        .EXAMPLE
        $relay = Start-Relay -Pipe $agente.Nome
        #>
        [CmdletBinding()]
        [OutputType([Diagnostics.Process])]
        param(
            [Parameter(Mandatory)] [string] $Pipe
        )

        $inicio = New-Object Diagnostics.ProcessStartInfo($caminhoDoRelay, $Pipe)
        $inicio.UseShellExecute = $false
        $inicio.RedirectStandardInput = $true
        $inicio.RedirectStandardOutput = $true
        $inicio.RedirectStandardError = $true

        $codificacaoDaEntrada = [Console]::InputEncoding
        [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
        try {
            return [Diagnostics.Process]::Start($inicio)
        }
        finally {
            [Console]::InputEncoding = $codificacaoDaEntrada
        }
    }

    function Wait-Relay {
        <#
        .SYNOPSIS
        Espera o relay sair por até 10 segundos, encerra o processo se ele não sair e diz se ele saiu sozinho.

        .PARAMETER Relay
        O processo que Start-Relay devolveu.

        .EXAMPLE
        $saiuSozinho = Wait-Relay -Relay $relay
        #>
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory)] [Diagnostics.Process] $Relay
        )

        $saiuSozinho = $Relay.WaitForExit(10000)
        if (-not $saiuSozinho) {
            $Relay.Kill()
            $null = $Relay.WaitForExit(5000)
        }

        return $saiuSozinho
    }

    function Read-SaidaDoRelay {
        <#
        .SYNOPSIS
        Lê a quantidade escolhida de bytes da saída do relay, até a saída terminar ou passar 10 segundos sem resposta.

        .PARAMETER Relay
        O processo que Start-Relay devolveu.

        .PARAMETER Quantidade
        Quantos bytes ler.

        .EXAMPLE
        $resposta = Read-SaidaDoRelay -Relay $relay -Quantidade 9
        #>
        [CmdletBinding()]
        [OutputType([byte[]])]
        param(
            [Parameter(Mandatory)] [Diagnostics.Process] $Relay,
            [Parameter(Mandatory)] [int] $Quantidade
        )

        $buffer = New-Object byte[] $Quantidade
        $lidos = 0
        $leitura = -1
        while ($lidos -lt $Quantidade -and $leitura -ne 0) {
            $tarefa = $Relay.StandardOutput.BaseStream.ReadAsync($buffer, $lidos, $Quantidade - $lidos)
            $respondeu = $tarefa.Wait(10000)
            $leitura = 0
            if ($respondeu) {
                $leitura = $tarefa.Result
            }
            $lidos += $leitura
        }

        return , @($buffer | Select-Object -First $lidos)
    }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Relay do agente SSH' {
    Context 'quando o agente está rodando' {
        BeforeAll {
            $agente = Start-AgenteSshFalso
        }

        AfterAll {
            Stop-AgenteSshFalso -Agente $agente
        }

        It 'repassa o pedido que chega depois da conexão e devolve a resposta do agente' {
            $relay = Start-Relay -Pipe $agente.Nome
            Start-Sleep -Milliseconds 500
            $relay.StandardInput.BaseStream.Write($agente.PedidoDeChaves, 0, $agente.PedidoDeChaves.Length)
            $relay.StandardInput.BaseStream.Flush()
            $resposta = Read-SaidaDoRelay -Relay $relay -Quantidade $agente.RespostaDeChaves.Length

            $relay.StandardInput.Close()
            $null = Wait-Relay -Relay $relay

            ($resposta -join ',') | Should-Be ($agente.RespostaDeChaves -join ',')
        }

        It 'sai sem erro quando a entrada termina' {
            $relay = Start-Relay -Pipe $agente.Nome

            $relay.StandardInput.Close()
            $saiuSozinho = Wait-Relay -Relay $relay

            "$saiuSozinho $($relay.ExitCode)" | Should-Be 'True 0' -Because $relay.StandardError.ReadToEnd()
        }
    }

    Context 'quando o pipe não existe' {
        BeforeAll {
            $relay = Start-Relay -Pipe "winplaybook-inexistente-$([guid]::NewGuid().ToString('N'))"
            $null = Wait-Relay -Relay $relay
            $erro = $relay.StandardError.ReadToEnd()
        }

        It 'sai com erro' {
            $relay.ExitCode | Should-Be 1
        }

        It 'explica o erro no stderr' {
            $erro | Should-BeLikeString 'WinPlaybook: *'
        }
    }
}
