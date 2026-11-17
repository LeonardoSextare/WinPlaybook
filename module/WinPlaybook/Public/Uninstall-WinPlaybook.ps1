function Uninstall-WinPlaybook {
    <#
    .SYNOPSIS
    Apaga a distribuição WSL do WinPlaybook e os shims de comando, e tira a pasta deles do Path do usuário.

    .DESCRIPTION
    A distribuição WinPlaybook é apagada com tudo o que há nela, como as collections e as
    roles que o ansible-galaxy instalou e as chaves SSH guardadas no Linux. Por isso o
    comando pede confirmação; use -Confirm:$false para pular. Também apaga a configuração do
    WinPlaybook. A pasta escolhida com o -Path do Install-WinPlaybook fica, e só a pasta
    WinPlaybook criada dentro dela é apagada. A pasta .ssh do usuário que a instalação
    criou é apagada só se continuar vazia.

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

    $criouAPastaDoSsh = [bool] (Get-Configuracao).CreatedSshFolder
    Remove-DistribuicaoDoWinPlaybook -Nome $distribuicao -Pasta (Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'distro')
    Remove-PastaDosShims -Pasta $pastaDosShims
    if ($criouAPastaDoSsh) {
        Remove-PastaVazia -Pasta (Get-PastaDoSshDoUsuario)
    }
    Remove-Configuracao
}
