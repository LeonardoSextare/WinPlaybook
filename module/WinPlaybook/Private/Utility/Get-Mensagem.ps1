function Get-Mensagem {
    <#
    .SYNOPSIS
    Devolve uma mensagem do WinPlaybook no idioma da interface do Windows, em português ou inglês.

    .DESCRIPTION
    As mensagens ficam nos arquivos pt-BR\Mensagens.psd1 e en-US\Mensagens.psd1 da pasta do
    módulo, com as mesmas chaves. Um idioma sem arquivo usa o inglês. Os marcadores {0},
    {1}... da mensagem viram os valores, na ordem.

    .PARAMETER Nome
    A chave da mensagem, como DistribuicaoNaoExiste.

    .PARAMETER Valores
    Os valores dos marcadores da mensagem.

    .EXAMPLE
    Get-Mensagem -Nome 'DistribuicaoNaoExiste' -Valores 'Fedora', 'Ubuntu, Debian'

    Devolve "A distribuição WSL Fedora não existe. Escolha uma das distribuições instaladas: Ubuntu, Debian." num Windows em português.

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/import-localizeddata
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [AllowEmptyCollection()] [object[]] $Valores = @()
    )

    $pastaDoModulo = $ExecutionContext.SessionState.Module.ModuleBase
    $cultura = Get-CulturaDaInterface
    $temMensagensNoIdioma = $cultura -and (Test-Path -LiteralPath (Join-Path -Path $pastaDoModulo -ChildPath "$cultura\Mensagens.psd1"))
    if (-not $temMensagensNoIdioma) {
        $cultura = 'en-US'
    }

    $mensagens = Import-LocalizedData -BaseDirectory $pastaDoModulo -FileName 'Mensagens.psd1' -UICulture $cultura
    return $mensagens[$Nome] -f $Valores
}
