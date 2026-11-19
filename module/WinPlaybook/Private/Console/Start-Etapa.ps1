function Start-Etapa {
    <#
    .SYNOPSIS
    Começa uma etapa demorada, mostrando no console o que está sendo feito, e devolve o controle dela para o Complete-Etapa.

    .DESCRIPTION
    Num terminal interativo, a linha da etapa mostra um indicador que gira ao lado do texto,
    para o usuário saber que nada travou. A animação roda num runspace separado e reescreve
    a linha a cada 120 ms, mesmo com a thread principal parada esperando um programa, como o
    wsl.exe. O Set-TextoDaEtapa troca o texto enquanto a etapa roda. Fora de um terminal
    interativo, nada aparece até o Complete-Etapa.

    A etapa em andamento fica guardada no módulo, para o Stop-EtapaAtual parar a animação
    quando o comando é interrompido, como por um Ctrl+C.

    .PARAMETER Texto
    O que a etapa está fazendo, no gerúndio, como "Instalando o Ansible".

    .EXAMPLE
    $etapa = Start-Etapa -Texto 'Instalando o Ansible'
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [string] $Texto
    )

    $etapa = @{
        Texto      = $Texto
        Relogio    = [Diagnostics.Stopwatch]::StartNew()
        Estado     = [hashtable]::Synchronized(@{ Rodando = $true; Texto = $Texto; Largura = $Texto.Length })
        PowerShell = $null
        Execucao   = $null
    }
    $script:EtapaAtual = $etapa
    $mostraAnimacao = (Test-SessaoInterativa) -and -not [Console]::IsOutputRedirected
    if (-not $mostraAnimacao) {
        return $etapa
    }

    $etapa.PowerShell = [powershell]::Create()
    $null = $etapa.PowerShell.AddScript({
        param($Estado)
        $quadros = '|', '/', '-', '\'
        $quadro = 0
        $corOriginal = [Console]::ForegroundColor
        while ($Estado.Rodando) {
            $texto = $Estado.Texto
            [Console]::Write("`r  [")
            [Console]::ForegroundColor = 'Cyan'
            [Console]::Write($quadros[$quadro % 4])
            [Console]::ForegroundColor = $corOriginal
            [Console]::Write('] ' + $texto.PadRight($Estado.Largura))
            $quadro++
            Start-Sleep -Milliseconds 120
        }
    }).AddArgument($etapa.Estado)
    $etapa.Execucao = $etapa.PowerShell.BeginInvoke()

    return $etapa
}
