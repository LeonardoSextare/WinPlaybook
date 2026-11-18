function Uninstall-WinPlaybook {
    <#
    .SYNOPSIS
    Apaga a distribuição WSL do WinPlaybook e os shims de comando, e tira a pasta deles do Path do usuário.

    .DESCRIPTION
    A distribuição WinPlaybook é apagada com tudo o que há nela, como as collections e as
    roles que o ansible-galaxy instalou e as chaves SSH guardadas no Linux. Por isso o
    comando pede confirmação; use -Confirm:$false para pular. Também apaga a configuração e os logs do
    WinPlaybook. A pasta escolhida com o -Path do Install-WinPlaybook fica, e só a pasta
    WinPlaybook criada dentro dela é apagada. A pasta .ssh do usuário que a instalação
    criou é apagada só se continuar vazia. As correções do Enable-WinPlaybookVSCodeExtension
    na extensão Ansible do VS Code são desfeitas. A linha do autocomplete sai dos perfis do
    PowerShell, e um perfil que fica vazio é apagado.

    .EXAMPLE
    Uninstall-WinPlaybook

    .EXAMPLE
    Uninstall-WinPlaybook -Confirm:$false

    Desinstala sem pedir confirmação.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param()

    $distribuicao = 'WinPlaybook'
    $pastaDosShims = Get-PastaDosShims
    $confirmou = $PSCmdlet.ShouldProcess($distribuicao, (Get-Mensagem -Nome 'DesinstalarWinPlaybook' -Valores $distribuicao, $pastaDosShims))
    if (-not $confirmou) {
        return
    }

    Disable-WinPlaybookLocalhost -Confirm:$false
    $criouAPastaDoSsh = [bool] (Get-Configuracao).CreatedSshFolder
    Remove-DistribuicaoDoWinPlaybook -Nome $distribuicao -Pasta (Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'distro')
    Remove-PastaDosShims -Pasta $pastaDosShims
    if ($criouAPastaDoSsh) {
        Remove-PastaVazia -Pasta (Get-PastaDoSshDoUsuario)
    }
    Remove-PastaDoAnsibleVazia -PastaDoPerfil (Get-PastaDoPerfilDoUsuario)
    foreach ($perfil in Get-PerfilDoPowerShell) {
        Remove-AutocompleteDoPerfil -Perfil $perfil
    }
    foreach ($extensao in Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes (Get-PastaDasExtensoesDoVSCode)) {
        Remove-PatchDaExtensaoAnsible -Caminho $extensao.Caminho
    }
    Remove-Item -LiteralPath (Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'logs') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Configuracao
}
