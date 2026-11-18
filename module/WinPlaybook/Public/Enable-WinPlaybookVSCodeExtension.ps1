function Enable-WinPlaybookVSCodeExtension {
    <#
    .SYNOPSIS
    Corrige a extensão Ansible do VS Code para ela funcionar no Windows com o WinPlaybook.

    .DESCRIPTION
    O language server da extensão Ansible (redhat.ansible) foi feito para o Linux. O comando
    aplica a ele as correções que o fazem funcionar no Windows, na versão mais nova da
    extensão instalada em %USERPROFILE%\.vscode\extensions, desde que o WinPlaybook já tenha
    testado essa versão. Os arquivos originais ficam guardados, e o
    Disable-WinPlaybookVSCodeExtension e o Uninstall-WinPlaybook os devolvem.

    Uma atualização da extensão desfaz as correções. Por isso, desligue a atualização
    automática da extensão e mantenha a versão testada. O comando não altera as
    configurações do VS Code: o objeto que ele devolve tem, em RequiredSettings, o que o
    settings.json do usuário precisa ter.

    .EXAMPLE
    Enable-WinPlaybookVSCodeExtension

    Corrige a extensão e mostra a versão, a pasta e as configurações necessárias.

    .LINK
    https://leonardosextare.github.io/WinPlaybook/pt-br/enable-winplaybookvscodeextension/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param()

    $pastaDasExtensoes = Get-PastaDasExtensoesDoVSCode
    $patches = Get-PatchDaExtensaoAnsible
    $versaoTestada = @($patches.Keys | Sort-Object -Property { [version] $_ })[-1]
    $extensoes = @(Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes $pastaDasExtensoes | Sort-Object -Property { [version] $_.Versao })
    $temExtensao = $extensoes.Count -gt 0
    if (-not $temExtensao) {
        throw (Get-Mensagem -Nome 'ExtensaoAnsibleNaoEncontrada' -Valores $pastaDasExtensoes, $versaoTestada)
    }

    $extensao = $extensoes[-1]
    $versaoFoiTestada = $patches.ContainsKey($extensao.Versao)
    if (-not $versaoFoiTestada) {
        throw (Get-Mensagem -Nome 'VersaoDaExtensaoAnsibleNaoTestada' -Valores $extensao.Versao, $versaoTestada)
    }

    $confirmou = $PSCmdlet.ShouldProcess($extensao.Caminho, (Get-Mensagem -Nome 'AtivarExtensaoAnsible' -Valores $extensao.Caminho))
    if (-not $confirmou) {
        return
    }

    Install-PatchDaExtensaoAnsible -Caminho $extensao.Caminho -Trocas $patches[$extensao.Versao] -Versao $extensao.Versao
    return [pscustomobject]@{
        Version          = $extensao.Versao
        Path             = $extensao.Caminho
        RequiredSettings = [ordered]@{ 'security.allowedUNCHosts' = @('wsl.localhost') }
    }
}
