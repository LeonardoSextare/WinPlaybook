function Disable-WinPlaybookVSCodeExtension {
    <#
    .SYNOPSIS
    Desfaz as correções do WinPlaybook na extensão Ansible do VS Code.

    .DESCRIPTION
    Devolve os arquivos originais da extensão Ansible (redhat.ansible) em todas as versões
    instaladas em %USERPROFILE%\.vscode\extensions que o Enable-WinPlaybookVSCodeExtension
    corrigiu. Uma versão sem as correções fica como está.

    .EXAMPLE
    Disable-WinPlaybookVSCodeExtension

    .LINK
    https://leonardosextare.github.io/WinPlaybook/pt-br/disable-winplaybookvscodeextension/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    foreach ($extensao in Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes (Get-PastaDasExtensoesDoVSCode)) {
        $confirmou = $PSCmdlet.ShouldProcess($extensao.Caminho, (Get-Mensagem -Nome 'DesativarExtensaoAnsible' -Valores $extensao.Caminho))
        if ($confirmou) {
            Remove-PatchDaExtensaoAnsible -Caminho $extensao.Caminho
        }
    }
}
