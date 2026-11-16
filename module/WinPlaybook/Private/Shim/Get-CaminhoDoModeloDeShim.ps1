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

    $caminhoDoModelo = Join-Path -Path $ExecutionContext.SessionState.Module.ModuleBase -ChildPath 'bin\shim.exe'

    $estaEmpacotado = Test-Path -LiteralPath $caminhoDoModelo
    if (-not $estaEmpacotado) {
        throw (Get-Mensagem -Nome 'ShimNaoEmpacotado' -Valores $caminhoDoModelo)
    }

    return $caminhoDoModelo
}
