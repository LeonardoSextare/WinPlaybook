function New-ShimDeComando {
    <#
    .SYNOPSIS
    Cria os arquivos .ps1, .exe e .shim que deixam um comando da distribuição WSL disponível no Windows.

    .DESCRIPTION
    O PowerShell executa o .ps1 no próprio processo. Os outros programas executam o .exe,
    uma cópia do shim empacotado, que abre o PowerShell escolhido com o mesmo .ps1.

    .PARAMETER Nome
    O nome do comando na distribuição, como ansible-playbook.

    .PARAMETER Pasta
    A pasta onde os três arquivos são criados.

    .PARAMETER CaminhoDoPowerShell
    O PowerShell que o .exe abre.

    .EXAMPLE
    New-ShimDeComando -Nome 'ansible-playbook' -Pasta 'C:\shims' -CaminhoDoPowerShell 'C:\Program Files\PowerShell\7\pwsh.exe'

    Cria ansible-playbook.ps1, ansible-playbook.exe e ansible-playbook.shim em C:\shims.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $Pasta,
        [Parameter(Mandatory)] [string] $CaminhoDoPowerShell
    )

    $caminhoDoScript = Join-Path -Path $Pasta -ChildPath "$Nome.ps1"
    Set-Content -LiteralPath $caminhoDoScript -Value "WinPlaybook\Invoke-WinPlaybook '$Nome' @args; exit `$LASTEXITCODE" -Encoding UTF8

    Copy-Item -LiteralPath (Get-CaminhoDoModeloDeShim) -Destination (Join-Path -Path $Pasta -ChildPath "$Nome.exe") -Force

    Set-Content -LiteralPath (Join-Path -Path $Pasta -ChildPath "$Nome.shim") -Encoding UTF8 -Value @(
        "path = $CaminhoDoPowerShell"
        "args = -NoProfile -ExecutionPolicy Bypass -File `"$caminhoDoScript`""
    )
}
