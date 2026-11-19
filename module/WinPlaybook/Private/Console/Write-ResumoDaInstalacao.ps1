function Write-ResumoDaInstalacao {
    <#
    .SYNOPSIS
    Escreve no console o fim da instalação: que ela terminou, quantos comandos criou, o próximo passo e os primeiros passos.

    .DESCRIPTION
    Com a extensão do VS Code corrigida, inclui a linha que o settings.json do usuário
    precisa ter, porque o WinPlaybook não altera as configurações do VS Code.

    .PARAMETER QuantidadeDeComandos
    Quantos comandos do Ansible a instalação criou no Windows.

    .PARAMETER CorrigiuOVSCode
    A extensão Ansible do VS Code foi corrigida nesta instalação.

    .EXAMPLE
    Write-ResumoDaInstalacao -QuantidadeDeComandos 12 -CorrigiuOVSCode
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [int] $QuantidadeDeComandos,
        [switch] $CorrigiuOVSCode
    )

    Write-Host ''
    Write-Host "$(Get-Mensagem -Nome 'InstalacaoConcluida') " -ForegroundColor Green -NoNewline
    Write-Host "$(Get-Mensagem -Nome 'ProximoPasso') " -NoNewline
    Write-Host 'ansible --version' -ForegroundColor Cyan
    Write-Host (Get-Mensagem -Nome 'ComandosCriados' -Valores $QuantidadeDeComandos) -ForegroundColor DarkGray
    if ($CorrigiuOVSCode) {
        Write-Host "$(Get-Mensagem -Nome 'ConfiguracaoDoVSCode') " -ForegroundColor DarkGray -NoNewline
        Write-Host '"security.allowedUNCHosts": ["wsl.localhost"]' -ForegroundColor Cyan
    }
    Write-Host (Get-Mensagem -Nome 'PrimeirosPassos' -Valores (Get-Mensagem -Nome 'PaginaDaDocumentacao' -Valores 'first-playbook')) -ForegroundColor DarkGray
}
