function Write-ResumoDaInstalacao {
    <#
    .SYNOPSIS
    Escreve no console o fim da instalação: que ela terminou, o próximo passo e os primeiros passos.

    .DESCRIPTION
    Com a extensão do VS Code corrigida, inclui a linha que o settings.json do usuário
    precisa ter, porque o WinPlaybook não altera as configurações do VS Code.

    .PARAMETER CorrigiuOVSCode
    A extensão Ansible do VS Code foi corrigida nesta instalação.

    .EXAMPLE
    Write-ResumoDaInstalacao -CorrigiuOVSCode
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [switch] $CorrigiuOVSCode
    )

    Write-Host ''
    Write-Host "$(Get-Mensagem -Nome 'InstalacaoConcluida') " -ForegroundColor Green -NoNewline
    Write-Host "$(Get-Mensagem -Nome 'ProximoPasso') " -NoNewline
    Write-Host 'ansible --version' -ForegroundColor Cyan
    if ($CorrigiuOVSCode) {
        Write-Host "$(Get-Mensagem -Nome 'ConfiguracaoDoVSCode') " -ForegroundColor DarkGray -NoNewline
        Write-Host '"security.allowedUNCHosts": ["wsl.localhost"]' -ForegroundColor Cyan
    }
    Write-Host (Get-Mensagem -Nome 'PrimeirosPassos' -Valores (Get-Mensagem -Nome 'PaginaDaDocumentacao' -Valores 'first-playbook')) -ForegroundColor DarkGray
}
