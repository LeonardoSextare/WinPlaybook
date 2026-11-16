function New-DistribuicaoDoWinPlaybook {
    <#
    .SYNOPSIS
    Cria a distribuição WSL do WinPlaybook, com o Debian do catálogo do WSL.

    .DESCRIPTION
    A distribuição é baixada da internet, sem a Microsoft Store, e criada no WSL 2, com o
    disco na pasta escolhida. Ela fica parada até o primeiro comando e ainda não tem o
    Ansible: Initialize-DistribuicaoDoWinPlaybook e Install-AnsibleNaDistribuicao preparam o
    resto.

    .PARAMETER Nome
    O nome da distribuição no WSL.

    .PARAMETER Pasta
    A pasta onde o WSL guarda o disco da distribuição.

    .EXAMPLE
    New-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -Pasta 'C:\Users\<usuário>\AppData\Local\WinPlaybook\distro'

    .LINK
    https://learn.microsoft.com/windows/wsl/basic-commands#install
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $Pasta
    )

    $argumentosDoWsl = @('--install', 'Debian', '--name', $Nome, '--location', $Pasta, '--version', '2', '--web-download', '--no-launch')

    $utf8Original = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $ErrorActionPreference = 'Continue'
        $saida = @(wsl @argumentosDoWsl 2>&1 | ForEach-Object { "$_" })
    }
    finally {
        $env:WSL_UTF8 = $utf8Original
    }

    $criou = $LASTEXITCODE -eq 0
    if (-not $criou) {
        throw (Get-Mensagem -Nome 'DistribuicaoNaoCriada' -Valores $Nome, (($saida -join ' ').Trim()))
    }
}
