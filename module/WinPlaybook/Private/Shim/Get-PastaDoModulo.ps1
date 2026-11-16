function Get-PastaDoModulo {
    <#
    .SYNOPSIS
    Devolve a pasta que os shims passam ao Import-Module para carregar o WinPlaybook.

    .DESCRIPTION
    Instalado pela PowerShell Gallery, o módulo fica numa pasta com o número da versão,
    como Modules\WinPlaybook\1.2.0. Nesse caso, a pasta devolvida é a de cima, sem a versão:
    o Import-Module carrega a versão mais nova dela, então os shims acompanham as
    atualizações. Fora de uma pasta de versão, como num clone do repositório, a pasta
    devolvida é a do próprio módulo.

    .EXAMPLE
    Get-PastaDoModulo

    Devolve C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $pastaDoModulo = $ExecutionContext.SessionState.Module.ModuleBase
    $pastaDeCima = Split-Path -Path $pastaDoModulo -Parent

    $estaNumaPastaDeVersao = ([bool] ((Split-Path -Path $pastaDoModulo -Leaf) -as [version])) -and ((Split-Path -Path $pastaDeCima -Leaf) -eq 'WinPlaybook')
    if ($estaNumaPastaDeVersao) {
        return $pastaDeCima
    }

    return $pastaDoModulo
}
