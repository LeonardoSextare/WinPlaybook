function Install-WinPlaybook {
    <#
    .SYNOPSIS
    Instala o Ansible numa distribuição WSL própria do WinPlaybook e deixa os comandos dele, como o ansible-playbook, disponíveis no Windows.

    .DESCRIPTION
    Na primeira vez, cria a distribuição WSL WinPlaybook, com o Debian, e a prepara para o
    Ansible. Depois instala o pacote ansible, com as collections dele, o ansible-lint, o
    pywinrm e os pacotes Python pedidos. A distribuição é do WinPlaybook: o WinPlaybook a
    configura, e a desinstalação a apaga. Se a primeira instalação falha, a distribuição
    criada nela é apagada.

    O ssh da distribuição usa a pasta .ssh do Windows (%USERPROFILE%\.ssh) como ~/.ssh, com
    as chaves, o known_hosts e o config dela, sem cópias. Quando a pasta ainda não existe, a
    instalação a cria vazia, como o ssh do Windows faria no primeiro uso, e a desinstalação a
    apaga se ela continuar vazia. Quando o agente SSH
    do Windows está rodando, o ssh da distribuição usa as chaves que estão nele, pelo relay
    do agente SSH, que fica na subpasta exe da pasta dos shims.

    O Ansible usa o perfil do Windows como o do usuário: o .ansible.cfg do perfil, as
    pastas .ansible\collections e .ansible\roles, que a instalação cria, para o que o
    ansible-galaxy instala, e o nome do usuário do Windows como usuário padrão do ssh. A
    desinstalação apaga essas pastas só se continuarem vazias.

    Para cada comando do Ansible, cria um .ps1, que o PowerShell executa, e um .exe, que os
    outros programas executam, e coloca a pasta deles no Path do usuário. O .exe é compilado
    na instalação pelo compilador de C# do .NET Framework, que vem no Windows. A pasta também é
    do WinPlaybook: uma nova instalação substitui tudo o que há nela. Os shims carregam o
    módulo pela pasta onde ele está instalado, então funcionam nas duas edições do
    PowerShell e acompanham as atualizações do módulo nessa pasta.

    O perfil do PowerShell 7 e o do Windows PowerShell 5.1 (profile.ps1, em Documentos)
    recebem uma linha que liga o autocomplete dos comandos do Ansible, pelo
    Register-WinPlaybookArgumentCompleter. Um perfil que não existe é criado, e a
    desinstalação tira a linha.

    Rode de novo para atualizar o Ansible, para trocar a versão ou os pacotes Python, ou
    depois de mudar o módulo de pasta. A instalação precisa do WSL e da internet.

    Antes de começar, num terminal interativo, a instalação pergunta se o usuário quer ligar
    o localhost_windows e, com a extensão Ansible do VS Code instalada, corrigir a extensão.
    Depois, o console mostra o plano com todas as etapas, e o sinal de cada uma muda enquanto a instalação avança; o fim mostra o próximo passo. Com
    -PassThru, devolve um objeto com a pasta dos shims (Folder), a distribuição
    (Distribution) e os comandos (Commands).

    .PARAMETER Path
    A pasta onde a pasta WinPlaybook é criada; os shims ficam em <Path>\WinPlaybook\bin. O
    padrão é %LOCALAPPDATA%\WinPlaybook\bin.

    .PARAMETER PowerShell
    O PowerShell que os shims .exe abrem: Desktop (o Windows PowerShell 5.1, que abre mais
    rápido) ou Core (o PowerShell 7). O padrão é o escolhido na instalação anterior ou, na
    primeira instalação, o PowerShell que executa este comando.

    .PARAMETER AnsibleVersion
    A versão do pacote ansible, como 13.0.0 ou 13.*. O padrão é a escolhida na instalação
    anterior ou, sem uma escolha, a mais nova. Uma versão vazia ('') volta para a mais nova.

    .PARAMETER PythonPackage
    Os pacotes Python que as collections precisam, como boto3, no formato do pip. O padrão
    são os escolhidos na instalação anterior. Uma lista vazia (@()) tira os pacotes extras. Os
    comandos desses pacotes, como o yamllint, ganham shims como os do Ansible.

    .PARAMETER EnableLocalhost
    Liga o localhost_windows sem perguntar, como o Enable-WinPlaybookLocalhost. Sem este
    parâmetro, a instalação pergunta antes de começar, num terminal interativo, e guarda a
    recusa.

    .PARAMETER EnableVSCodeExtension
    Corrige a extensão Ansible do VS Code sem perguntar, como o
    Enable-WinPlaybookVSCodeExtension.

    .PARAMETER PassThru
    Devolve o objeto com a pasta dos shims, a distribuição e os comandos.

    .EXAMPLE
    Install-WinPlaybook

    .EXAMPLE
    Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3', 'netaddr'

    Instala a versão 12 mais nova do Ansible, com os pacotes boto3 e netaddr.

    .EXAMPLE
    Install-WinPlaybook -Path 'C:\Tools' -PowerShell Desktop

    Cria os shims em C:\Tools\WinPlaybook\bin, abertos pelo Windows PowerShell 5.1.

    .LINK
    https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

    .LINK
    https://leonardosextare.github.io/WinPlaybook/pt-br/install-winplaybook/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [string] $Path,
        [ValidateSet('Desktop', 'Core')] [string] $PowerShell,
        [AllowEmptyString()] [string] $AnsibleVersion,
        [AllowEmptyCollection()] [string[]] $PythonPackage,
        [switch] $EnableLocalhost,
        [switch] $EnableVSCodeExtension,
        [switch] $PassThru
    )

    $distribuicao = 'WinPlaybook'

    $pastaDosShims = Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'bin'
    $pastaFoiEscolhida = [bool] $Path
    if ($pastaFoiEscolhida) {
        $pastaDosShims = Join-Path -Path $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path) -ChildPath 'WinPlaybook\bin'
    }

    $configuracao = Get-Configuracao
    $pastaAnterior = $configuracao.ShimFolder
    $ehAPastaAnterior = $pastaAnterior -eq $pastaDosShims
    $pastaEhDeOutroDono = (Test-Path -LiteralPath $pastaDosShims) -and -not $ehAPastaAnterior
    if ($pastaEhDeOutroDono) {
        throw (Get-Mensagem -Nome 'PastaDeOutroDono' -Valores $pastaDosShims)
    }

    $wslEstaInstalado = Test-WslInstalado
    if (-not $wslEstaInstalado) {
        throw (Get-Mensagem -Nome 'WslNaoInstalado')
    }

    $versaoDoAnsible = "$($configuracao.AnsibleVersion)"
    $versaoFoiEscolhida = $PSBoundParameters.ContainsKey('AnsibleVersion')
    if ($versaoFoiEscolhida) {
        $versaoDoAnsible = $AnsibleVersion
    }

    $pacotesPython = @($configuracao.PythonPackages | Where-Object { $_ })
    $pacotesForamEscolhidos = $PSBoundParameters.ContainsKey('PythonPackage')
    if ($pacotesForamEscolhidos) {
        $pacotesPython = @($PythonPackage | Where-Object { $_ })
    }

    $confirmou = $PSCmdlet.ShouldProcess($distribuicao, (Get-Mensagem -Nome 'InstalarWinPlaybook' -Valores $distribuicao, $pastaDosShims))
    if (-not $confirmou) {
        return
    }

    $escolhas = Get-EscolhaDaInstalacao -Configuracao $configuracao -LigarLocalhost:$EnableLocalhost -CorrigirVSCode:$EnableVSCodeExtension
    Write-Host ''

    $pastaDaDistribuicao = Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'distro'
    $distribuicaoJaExistia = $distribuicao -in @(Get-DistribuicaoDoWsl)
    $passos = @(
        if (-not $distribuicaoJaExistia) { @{ Id = 'debian'; Texto = (Get-Mensagem -Nome 'PassoBaixarODebian') } }
        @{ Id = 'ambiente'; Texto = (Get-Mensagem -Nome 'PassoPrepararOAmbiente') }
        @{ Id = 'ansible'; Texto = (Get-Mensagem -Nome 'PassoInstalarOAnsible') }
        @{ Id = 'comandos'; Texto = (Get-Mensagem -Nome 'PassoCriarOsComandos') }
        if ($escolhas.LigarLocalhost) { Get-PassoDoLocalhostWindows }
        if ($escolhas.CorrigirVSCode) { @{ Id = 'vscode'; Texto = (Get-Mensagem -Nome 'PassoCorrigirOVSCode') } }
    )

    $relogio = [Diagnostics.Stopwatch]::StartNew()
    Write-Log -Nivel 'info' -Mensagem "Install-WinPlaybook começou: pasta dos shims $pastaDosShims, versão do Ansible '$versaoDoAnsible', $(@($pacotesPython).Count) pacotes Python extras"
    $pastaDoExecutavel = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "WinPlaybook-$([guid]::NewGuid().ToString('N'))"
    $caminhoDoExecutavel = Join-Path -Path $pastaDoExecutavel -ChildPath 'shim.exe'
    $caminhoDoRelay = Join-Path -Path $pastaDoExecutavel -ChildPath 'relay-do-agente-ssh.exe'
    $caminhoDoRelayDeRede = Join-Path -Path $pastaDoExecutavel -ChildPath 'relay-de-rede.exe'
    $falhas = [Collections.Generic.List[hashtable]]::new()
    $plano = New-Plano -Itens $passos
    try {
        New-ExecutavelDeShim -Caminho $caminhoDoExecutavel
        New-ExecutavelDoRelay -Caminho $caminhoDoRelay
        New-ExecutavelDoRelayDeRede -Caminho $caminhoDoRelayDeRede

        $pastaDoPerfil = Get-PastaDoPerfilDoUsuario
        $pastaDoSsh = Get-PastaDoSshDoUsuario
        $vaiCriarAPastaDoSsh = -not (Test-Path -LiteralPath $pastaDoSsh -PathType Container)
        try {
            if (-not $distribuicaoJaExistia) {
                Start-ItemDoPlano -Plano $plano -Id 'debian'
                New-DistribuicaoDoWinPlaybook -Nome $distribuicao -Pasta $pastaDaDistribuicao
            }
            if ($vaiCriarAPastaDoSsh) {
                $null = New-Item -ItemType Directory -Path $pastaDoSsh
            }
            Start-ItemDoPlano -Plano $plano -Id 'ambiente'
            Initialize-DistribuicaoDoWinPlaybook -Nome $distribuicao -PastaDoSsh $pastaDoSsh -PastaDoPerfil $pastaDoPerfil -UsuarioDoWindows (Get-NomeDoUsuarioDoWindows)
            Start-ItemDoPlano -Plano $plano -Id 'ansible'
            Install-AnsibleNaDistribuicao -Nome $distribuicao -VersaoDoAnsible $versaoDoAnsible -PacotesPython $pacotesPython
            $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $distribuicao
            $comandos = Get-ComandoDoAnsible -Distribuicao $distribuicao
            Complete-ItemDoPlano -Plano $plano -Id 'ansible'
        }
        catch {
            Complete-ItemDoPlano -Plano $plano -Falhou
            Write-Log -Nivel 'error' -Mensagem "Install-WinPlaybook falhou: $($_.Exception.Message)"
            if ($vaiCriarAPastaDoSsh) {
                Remove-PastaVazia -Pasta $pastaDoSsh
            }
            Remove-PastaDoAnsibleVazia -PastaDoPerfil $pastaDoPerfil
            if (-not $distribuicaoJaExistia) {
                Remove-DistribuicaoDoWinPlaybook -Nome $distribuicao -Pasta $pastaDaDistribuicao
            }
            throw
        }

        $caminhoDoPowerShell = $configuracao.ShimPowerShellPath
        $edicaoFoiEscolhida = [bool] $PowerShell
        if ($edicaoFoiEscolhida) {
            $caminhoDoPowerShell = Get-CaminhoDoPowerShell -Edicao $PowerShell
        }

        $powerShellExiste = $caminhoDoPowerShell -and (Test-Path -LiteralPath $caminhoDoPowerShell)
        if (-not $powerShellExiste) {
            $caminhoDoPowerShell = Get-CaminhoDoPowerShell
        }

        $pastaDoModulo = Get-PastaDoModulo

        $estaMudandoDePasta = $pastaAnterior -and -not $ehAPastaAnterior
        if ($estaMudandoDePasta) {
            Remove-PastaDosShims -Pasta $pastaAnterior
        }

        Start-ItemDoPlano -Plano $plano -Id 'comandos'
        Remove-Item -LiteralPath $pastaDosShims -Recurse -Force -ErrorAction SilentlyContinue
        $null = New-Item -ItemType Directory -Path $pastaDosShims -Force
        Save-Configuracao -Configuracao @{
            ShimFolder               = $pastaDosShims
            ShimPowerShellPath       = $caminhoDoPowerShell
            WslDistribution          = $distribuicao
            WslMountRoot             = $raizDeMontagem
            AnsibleVersion           = $versaoDoAnsible
            PythonPackages           = $pacotesPython
            CreatedSshFolder         = $vaiCriarAPastaDoSsh -or [bool] $configuracao.CreatedSshFolder
            LocalhostWindowsPort     = $configuracao['LocalhostWindowsPort']
            LocalhostWindowsUser     = $configuracao['LocalhostWindowsUser']
            LocalhostWindowsDeclined = $configuracao['LocalhostWindowsDeclined']
        }

        foreach ($comando in $comandos) {
            New-ShimDeComando -Nome $comando -Pasta $pastaDosShims -CaminhoDoPowerShell $caminhoDoPowerShell -PastaDoModulo $pastaDoModulo -CaminhoDoExecutavel $caminhoDoExecutavel
        }
        Install-RelayDoAgenteSsh -CaminhoDoExecutavel $caminhoDoRelay -PastaDosShims $pastaDosShims -Distribuicao $distribuicao -RaizDeMontagem $raizDeMontagem
        Install-RelayDeRede -CaminhoDoExecutavel $caminhoDoRelayDeRede -PastaDosShims $pastaDosShims -Distribuicao $distribuicao -RaizDeMontagem $raizDeMontagem
        Add-EntradaNoPathDoUsuario -Pasta $pastaDosShims
        foreach ($perfil in Get-PerfilDoPowerShell) {
            Add-AutocompleteNoPerfil -Perfil $perfil
        }
        Complete-ItemDoPlano -Plano $plano -Id 'comandos'

        if ($escolhas.LigarLocalhost) {
            try {
                Enable-WinPlaybookLocalhost -Confirm:$false
            }
            catch {
                Complete-ItemDoPlano -Plano $plano -Falhou
                $falhas.Add(@{ Causa = $_.Exception.Message; Comando = 'Enable-WinPlaybookLocalhost'; Pagina = 'troubleshooting-localhost-windows' })
            }
        }
        if ($escolhas.CorrigirVSCode) {
            try {
                Enable-WinPlaybookVSCodeExtension -Confirm:$false
            }
            catch {
                Complete-ItemDoPlano -Plano $plano -Falhou
                $falhas.Add(@{ Causa = $_.Exception.Message; Comando = 'Enable-WinPlaybookVSCodeExtension'; Pagina = 'troubleshooting-vscode' })
            }
        }
    }
    finally {
        Close-Plano -Plano $plano
        Remove-Item -LiteralPath $pastaDoExecutavel -Recurse -Force -ErrorAction SilentlyContinue
    }

    foreach ($falha in $falhas) {
        Write-FalhaDaEtapa -Causa $falha.Causa -Comando $falha.Comando -Pagina $falha.Pagina
    }
    Write-Log -Nivel 'info' -Mensagem "Install-WinPlaybook terminou em $($relogio.ElapsedMilliseconds) ms, com $(@($comandos).Count) comandos"
    $corrigiuOVSCode = $escolhas.CorrigirVSCode -and -not @($falhas | Where-Object { $_.Comando -eq 'Enable-WinPlaybookVSCodeExtension' }).Count
    Write-ResumoDaInstalacao -QuantidadeDeComandos @($comandos).Count -CorrigiuOVSCode:$corrigiuOVSCode
    if (-not $PassThru) {
        return
    }
    return [pscustomobject]@{
        Folder       = $pastaDosShims
        Distribution = $distribuicao
        Commands     = $comandos
    }
}
