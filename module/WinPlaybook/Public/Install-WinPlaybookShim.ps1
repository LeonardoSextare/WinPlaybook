function Install-WinPlaybookShim {
    <#
    .SYNOPSIS
    Deixa os comandos do Ansible de uma distribuição WSL, como o ansible-playbook, disponíveis como comandos do Windows.

    .DESCRIPTION
    Para cada comando do Ansible na distribuição, cria um .ps1, que o PowerShell executa, e
    um .exe, que os outros programas executam, e coloca a pasta deles no Path do usuário. A
    pasta é do WinPlaybook: uma nova instalação substitui tudo o que há nela, e a
    desinstalação a apaga.

    Os shims carregam o módulo pela pasta onde ele está instalado, então funcionam nas duas
    edições do PowerShell e acompanham as atualizações do módulo nessa pasta. Instale de
    novo depois de instalar ou remover comandos do Ansible na distribuição, ou depois de
    mudar o módulo de pasta.

    Devolve um objeto com a pasta dos shims (Folder), a distribuição (Distribution) e os
    comandos (Commands).

    .PARAMETER Distribution
    A distribuição WSL onde o Ansible está instalado, como o wsl --list mostra. É
    obrigatória na primeira instalação; depois, o padrão é a escolhida na instalação
    anterior.

    .PARAMETER Path
    A pasta onde a pasta WinPlaybook é criada; os shims ficam em <Path>\WinPlaybook\bin. O
    padrão é %LOCALAPPDATA%\WinPlaybook\bin.

    .PARAMETER PowerShell
    O PowerShell que os shims .exe abrem: Desktop (o Windows PowerShell 5.1, que abre mais
    rápido) ou Core (o PowerShell 7). O padrão é o escolhido na instalação anterior ou, na
    primeira instalação, o PowerShell que executa este comando.

    .EXAMPLE
    Install-WinPlaybookShim -Distribution Ubuntu

    .EXAMPLE
    Install-WinPlaybookShim -Path 'C:\Tools' -PowerShell Desktop

    Cria os shims em C:\Tools\WinPlaybook\bin, abertos pelo Windows PowerShell 5.1, para a
    distribuição escolhida na instalação anterior.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [string] $Distribution,
        [string] $Path,
        [ValidateSet('Desktop', 'Core')] [string] $PowerShell
    )

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

    $distribuicao = $configuracao.WslDistribution
    $distribuicaoFoiEscolhida = [bool] $Distribution
    if ($distribuicaoFoiEscolhida) {
        $distribuicao = $Distribution
    }

    $distribuicoesInstaladas = @(Get-DistribuicaoDoWsl)
    if (-not $distribuicao) {
        throw (Get-Mensagem -Nome 'EscolhaADistribuicao' -Valores ($distribuicoesInstaladas -join ', '))
    }

    $distribuicaoEstaInstalada = $distribuicao -in $distribuicoesInstaladas
    if (-not $distribuicaoEstaInstalada) {
        throw (Get-Mensagem -Nome 'DistribuicaoNaoExiste' -Valores $distribuicao, ($distribuicoesInstaladas -join ', '))
    }

    $confirmou = $PSCmdlet.ShouldProcess($pastaDosShims, (Get-Mensagem -Nome 'InstalarShims'))
    if (-not $confirmou) {
        return
    }

    $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $distribuicao
    $comandos = Get-ComandoDoAnsible -Distribuicao $distribuicao -RaizDeMontagem $raizDeMontagem

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
