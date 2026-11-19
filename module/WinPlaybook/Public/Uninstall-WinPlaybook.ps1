function Uninstall-WinPlaybook {
    <#
    .SYNOPSIS
    Apaga a distribuição WSL do WinPlaybook e os shims de comando, e tira a pasta deles do Path do usuário.

    .DESCRIPTION
    A distribuição WinPlaybook é apagada com tudo o que há nela, como os ambientes dos
    projetos e a chave do localhost_windows. Por isso o comando pede confirmação; use
    -Confirm:$false para pular. As collections e as roles que o ansible-galaxy instalou
    ficam no perfil do Windows, em .ansible\collections e .ansible\roles, e essas pastas só
    são apagadas se estiverem vazias. Também desliga o localhost_windows e apaga a
    configuração e os logs do WinPlaybook. A pasta escolhida com o -Path do Install-WinPlaybook fica, e só a pasta
    WinPlaybook criada dentro dela é apagada. A pasta .ssh do usuário que a instalação
    criou é apagada só se continuar vazia. As correções do Enable-WinPlaybookVSCodeExtension
    na extensão Ansible do VS Code são desfeitas. A linha do autocomplete sai dos perfis do
    PowerShell, e um perfil que fica vazio é apagado.

    .EXAMPLE
    Uninstall-WinPlaybook

    .EXAMPLE
    Uninstall-WinPlaybook -Confirm:$false

    Desinstala sem pedir confirmação.

    .LINK
    https://leonardosextare.github.io/WinPlaybook/pt-br/uninstall-winplaybook/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    $distribuicao = 'WinPlaybook'
    $pastaDosShims = Get-PastaDosShims
    $confirmou = $PSCmdlet.ShouldProcess($distribuicao, (Get-Mensagem -Nome 'DesinstalarWinPlaybook' -Valores $distribuicao, $pastaDosShims))
    if (-not $confirmou) {
        return
    }

    $vaiPerguntar = -not $PSBoundParameters.ContainsKey('Confirm') -and (Test-SessaoInterativa)
    if ($vaiPerguntar) {
        $aceitou = Read-Escolha -Pergunta (Get-Mensagem -Nome 'PerguntaDaDesinstalacao') -Explicacao (Get-Mensagem -Nome 'ExplicacaoDaDesinstalacao') -Link (Get-Mensagem -Nome 'PaginaDaDocumentacao' -Valores 'uninstall') -AjudaDoSim (Get-Mensagem -Nome 'OpcaoSimDaDesinstalacao') -AjudaDoNao (Get-Mensagem -Nome 'OpcaoNaoDaDesinstalacao') -PadraoNao
        if (-not $aceitou) {
            Write-Host (Get-Mensagem -Nome 'NadaFoiAlterado') -ForegroundColor DarkGray
            return
        }
        Write-Host ''
    }

    $localhostEstaLigado = [bool] (Get-Configuracao)['LocalhostWindowsPort']
    $extensoesCorrigidas = @(Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes (Get-PastaDasExtensoesDoVSCode) | Where-Object { Test-ExtensaoAnsibleCorrigida -Caminho $_.Caminho })
    $passos = @(
        if ($localhostEstaLigado) { Get-PassoDoLocalhostWindows -Desligar }
        if ($extensoesCorrigidas.Count -gt 0) { @{ Id = 'vscode'; Texto = (Get-Mensagem -Nome 'PassoDesfazerOVSCode') } }
        @{ Id = 'distribuicao'; Texto = (Get-Mensagem -Nome 'PassoApagarADistribuicao') }
        @{ Id = 'comandos'; Texto = (Get-Mensagem -Nome 'PassoRemoverOsComandos') }
    )

    $plano = New-Plano -Itens $passos
    try {
        Disable-WinPlaybookLocalhost -Confirm:$false

        Start-ItemDoPlano -Plano $plano -Id 'vscode'
        foreach ($extensao in $extensoesCorrigidas) {
            Remove-PatchDaExtensaoAnsible -Caminho $extensao.Caminho
        }
        Complete-ItemDoPlano -Plano $plano -Id 'vscode' -Remocao

        $criouAPastaDoSsh = [bool] (Get-Configuracao).CreatedSshFolder
        Start-ItemDoPlano -Plano $plano -Id 'distribuicao'
        Remove-DistribuicaoDoWinPlaybook -Nome $distribuicao -Pasta (Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'distro')
        Complete-ItemDoPlano -Plano $plano -Id 'distribuicao' -Remocao

        Start-ItemDoPlano -Plano $plano -Id 'comandos'
        Remove-PastaDosShims -Pasta $pastaDosShims
        if ($criouAPastaDoSsh) {
            Remove-PastaVazia -Pasta (Get-PastaDoSshDoUsuario)
        }
        Remove-PastaDoAnsibleVazia -PastaDoPerfil (Get-PastaDoPerfilDoUsuario)
        foreach ($perfil in Get-PerfilDoPowerShell) {
            Remove-AutocompleteDoPerfil -Perfil $perfil
        }
        Complete-ItemDoPlano -Plano $plano -Id 'comandos' -Remocao
    }
    finally {
        Close-Plano -Plano $plano
    }
    Remove-Item -LiteralPath (Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'logs') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Configuracao
    $comandoParaRemoverOModulo = 'Uninstall-Module WinPlaybook'
    $temPSResourceGet = [bool] (Get-Command -Name 'Uninstall-PSResource' -ErrorAction SilentlyContinue)
    if ($temPSResourceGet) {
        $comandoParaRemoverOModulo = 'Uninstall-PSResource WinPlaybook'
    }
    Write-Host ''
    Write-Host "$(Get-Mensagem -Nome 'DesinstalacaoConcluida') " -ForegroundColor Green -NoNewline
    Write-Host "$(Get-Mensagem -Nome 'RemoverOModulo') " -NoNewline
    Write-Host $comandoParaRemoverOModulo -ForegroundColor Cyan
}