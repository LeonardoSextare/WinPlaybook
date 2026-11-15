function Get-CaminhoDoModeloDeShim {
    <#
    .SYNOPSIS
    Devolve o caminho do shim.exe empacotado com o módulo, que é copiado para cada comando.

    .EXAMPLE
    Get-CaminhoDoModeloDeShim

    Devolve <pasta do módulo>\bin\shim.exe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $caminhoDoModelo = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\..\bin\shim.exe'))

    $estaEmpacotado = Test-Path -LiteralPath $caminhoDoModelo
    if (-not $estaEmpacotado) {
        throw "O shim.exe não está em $caminhoDoModelo. Reinstale o WinPlaybook, ou rode scripts/Save-Shim.ps1 num clone do repositório."
    }

    return $caminhoDoModelo
}
