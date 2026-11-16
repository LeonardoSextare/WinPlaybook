function Remove-DistribuicaoDoWinPlaybook {
    <#
    .SYNOPSIS
    Apaga a distribuição WSL do WinPlaybook, com tudo o que há nela, e a pasta onde ficava o disco dela.

    .DESCRIPTION
    Uma distribuição que não existe mais não é um erro. A pasta do disco só é apagada quando
    fica vazia.

    .PARAMETER Nome
    O nome da distribuição no WSL.

    .PARAMETER Pasta
    A pasta onde o WSL guardava o disco da distribuição.

    .EXAMPLE
    Remove-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -Pasta 'C:\Users\<usuário>\AppData\Local\WinPlaybook\distro'

    .LINK
    https://learn.microsoft.com/windows/wsl/basic-commands#unregister-or-uninstall-a-linux-distribution
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $Pasta
    )

    $distribuicaoExiste = $Nome -in @(Get-DistribuicaoDoWsl)
    if ($distribuicaoExiste) {
        $utf8Original = $env:WSL_UTF8
        $env:WSL_UTF8 = '1'
        try {
            $ErrorActionPreference = 'Continue'
            $saida = @(wsl --unregister $Nome 2>&1 | ForEach-Object { "$_" })
        }
        finally {
            $env:WSL_UTF8 = $utf8Original
        }

        $removeu = $LASTEXITCODE -eq 0
        if (-not $removeu) {
            throw (Get-Mensagem -Nome 'DistribuicaoNaoRemovida' -Valores $Nome, (($saida -join ' ').Trim()))
        }
    }

    Remove-PastaVazia -Pasta $Pasta
}
