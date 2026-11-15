function Get-PastaDosShims {
    <#
    .SYNOPSIS
    Devolve a pasta dos shims de comando: a salva na instalação ou a pasta padrão.

    .EXAMPLE
    Get-PastaDosShims

    Devolve C:\Users\<usuário>\AppData\Local\WinPlaybook\bin quando os shims estão na pasta padrão.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $pastaSalva = (Get-Configuracao).ShimFolder
    $estaInstalado = [bool] $pastaSalva
    if ($estaInstalado) {
        return $pastaSalva
    }

    return Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'bin'
}
