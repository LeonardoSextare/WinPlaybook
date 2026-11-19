function Show-AvisoDeVersaoNova {
    <#
    .SYNOPSIS
    Avisa no stderr, uma vez por sessão, que existe uma versão mais nova do WinPlaybook, com o comando para atualizar.

    .DESCRIPTION
    Usa a versão guardada por Update-VersaoMaisNovaGuardada, sem esperar a internet. Quando a
    versão guardada tem mais de uma hora, não existe ou não é mais nova que a atual, abre um PowerShell em segundo plano
    para consultá-la de novo, e o aviso usa a consulta nova no próximo comando. Não avisa
    quando a variável WINPLAYBOOK_UPDATE_CHECK é off, quando o stderr não é o terminal,
    como num programa que lê a saída, nem na versão de desenvolvimento (0.0.0). A sessão é
    a do módulo carregado: a do terminal do PowerShell, ou a de cada chamada de um shim .exe.

    .PARAMETER VersaoAtual
    A versão do módulo carregado.

    .EXAMPLE
    Show-AvisoDeVersaoNova -VersaoAtual '0.18.0'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [version] $VersaoAtual
    )

    $avisoEstaDesligado = "$env:WINPLAYBOOK_UPDATE_CHECK".Trim() -eq 'off'
    $ehVersaoDeDesenvolvimento = $VersaoAtual -eq [version] '0.0.0'
    $jaConferiuNaSessao = [bool] (Get-Variable -Name 'versaoNovaConferida' -Scope Script -ValueOnly -ErrorAction SilentlyContinue)
    $naoHaTerminal = -not (Test-SaidaDeErroNoTerminal)
    $naoDeveAvisar = $avisoEstaDesligado -or $ehVersaoDeDesenvolvimento -or $jaConferiuNaSessao -or $naoHaTerminal
    if ($naoDeveAvisar) {
        return
    }
    $script:versaoNovaConferida = $true

    $guardada = $null
    try {
        $guardada = Get-Content -LiteralPath (Get-CaminhoDaVersaoMaisNova) -Raw -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        $guardada = $null
    }

    $temVersaoMaisNova = $guardada -and $guardada.versao -and ([version] $guardada.versao -gt $VersaoAtual)
    $consultaVenceu = (-not $temVersaoMaisNova) -or (((Get-Date) - [datetime] $guardada.verificadoEm).TotalHours -ge 1)
    if ($consultaVenceu) {
        $comando = "Import-Module '$((Get-PastaDoModulo).Replace("'", "''"))'; & (Get-Module WinPlaybook) { Update-VersaoMaisNovaGuardada }"
        $null = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList '-NoProfile', '-NonInteractive', '-Command', $comando -WindowStyle Hidden
    }

    if ($temVersaoMaisNova) {
        [Console]::Error.WriteLine((Get-Mensagem -Nome 'AvisoDeVersaoNova' -Valores $guardada.versao, $VersaoAtual))
    }
}
