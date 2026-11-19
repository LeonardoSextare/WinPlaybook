function Start-ItemDoPlano {
    <#
    .SYNOPSIS
    Marca uma etapa do plano como em andamento, com o sinal girando no lugar dela.

    .DESCRIPTION
    A animação roda num runspace separado e reescreve o sinal da etapa a cada 120 ms, mesmo com
    a thread principal parada esperando um programa, como o wsl.exe. Uma etapa que já estava
    em andamento termina antes, com [+]. Fora de um terminal interativo, só o tempo começa a
    contar. Um Id que não está no plano não muda nada.

    .PARAMETER Plano
    O plano de New-Plano.

    .PARAMETER Id
    A etapa que começa.

    .EXAMPLE
    Start-ItemDoPlano -Plano $plano -Id 'ansible'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Plano,
        [Parameter(Mandatory)] [string] $Id
    )

    $principal = $Plano.Principal
    $temEtapa = $principal.Etapas.Contains($Id)
    if (-not $temEtapa) {
        return
    }

    $temOutraEmAndamento = [bool] $principal.EmAndamento
    if ($temOutraEmAndamento) {
        Complete-ItemDoPlano -Plano $principal -Id $principal.EmAndamento
    }

    $etapa = $principal.Etapas[$Id]
    $etapa.Relogio = [Diagnostics.Stopwatch]::StartNew()
    $principal.EmAndamento = $Id
    if (-not $principal.Interativo) {
        return
    }

    $estado = [hashtable]::Synchronized(@{ Rodando = $true })
    $powershell = [powershell]::Create()
    $null = $powershell.AddScript({
        param($Texto, $Recuo, $Linha, $Estado)
        $quadros = '|', '/', '-', '\'
        $quadro = 0
        $corOriginal = [Console]::ForegroundColor
        while ($Estado.Rodando) {
            $linhaDeVolta = [Console]::CursorTop
            [Console]::SetCursorPosition(0, $Linha)
            [Console]::Write('  ' + ('    ' * $Recuo) + '[')
            [Console]::ForegroundColor = 'Cyan'
            [Console]::Write($quadros[$quadro % 4])
            [Console]::ForegroundColor = $corOriginal
            [Console]::Write("] $Texto")
            [Console]::SetCursorPosition(0, $linhaDeVolta)
            $quadro++
            Start-Sleep -Milliseconds 120
        }
    }).AddArgument($etapa.Texto).AddArgument($etapa.Recuo).AddArgument($principal.PrimeiraLinha + $etapa.Indice).AddArgument($estado)
    $principal.Animacao = @{ PowerShell = $powershell; Execucao = $powershell.BeginInvoke(); Estado = $estado }
}
