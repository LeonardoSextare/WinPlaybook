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
    distribuição usa um ~/.ssh próprio; rode de novo depois de criá-la.

    Para cada comando do Ansible, cria um .ps1, que o PowerShell executa, e um .exe, que os
    outros programas executam, e coloca a pasta deles no Path do usuário. A pasta também é
    do WinPlaybook: uma nova instalação substitui tudo o que há nela. Os shims carregam o
    módulo pela pasta onde ele está instalado, então funcionam nas duas edições do
    PowerShell e acompanham as atualizações do módulo nessa pasta.

    Rode de novo para atualizar o Ansible, para trocar a versão ou os pacotes Python, ou
    depois de mudar o módulo de pasta. A instalação precisa do WSL e da internet.

    Devolve um objeto com a pasta dos shims (Folder), a distribuição (Distribution) e os
    comandos (Commands).

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
    são os escolhidos na instalação anterior. Uma lista vazia (@()) tira os pacotes extras.

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
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [string] $Path,
        [ValidateSet('Desktop', 'Core')] [string] $PowerShell,
        [AllowEmptyString()] [string] $AnsibleVersion,
        [AllowEmptyCollection()] [string[]] $PythonPackage
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

    $pastaDaDistribuicao = Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'distro'
    $distribuicaoJaExistia = $distribuicao -in @(Get-DistribuicaoDoWsl)
    if (-not $distribuicaoJaExistia) {
        New-DistribuicaoDoWinPlaybook -Nome $distribuicao -Pasta $pastaDaDistribuicao
    }

    try {
        Initialize-DistribuicaoDoWinPlaybook -Nome $distribuicao -PastaDoSsh (Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath '.ssh')
        Install-AnsibleNaDistribuicao -Nome $distribuicao -VersaoDoAnsible $versaoDoAnsible -PacotesPython $pacotesPython
        $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $distribuicao
        $comandos = Get-ComandoDoAnsible -Distribuicao $distribuicao -RaizDeMontagem $raizDeMontagem
    }
    catch {
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

    Remove-Item -LiteralPath $pastaDosShims -Recurse -Force -ErrorAction SilentlyContinue
    $null = New-Item -ItemType Directory -Path $pastaDosShims -Force
    Save-Configuracao -Configuracao @{
        ShimFolder         = $pastaDosShims
        ShimPowerShellPath = $caminhoDoPowerShell
        WslDistribution    = $distribuicao
        WslMountRoot       = $raizDeMontagem
        AnsibleVersion     = $versaoDoAnsible
        PythonPackages     = $pacotesPython
    }

    foreach ($comando in $comandos) {
        New-ShimDeComando -Nome $comando -Pasta $pastaDosShims -CaminhoDoPowerShell $caminhoDoPowerShell -PastaDoModulo $pastaDoModulo
    }
    Add-EntradaNoPathDoUsuario -Pasta $pastaDosShims

    return [pscustomobject]@{
        Folder       = $pastaDosShims
        Distribution = $distribuicao
        Commands     = $comandos
    }
}
