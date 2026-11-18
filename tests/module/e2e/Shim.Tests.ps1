BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Shim.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste

    $localAppDataOriginal = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'

    $pastaDeProgramasDoWindows = Join-Path $TestDrive 'programas-do-windows'
    $null = New-Item -ItemType File -Path (Join-Path $pastaDeProgramasDoWindows 'ansible-windows.exe') -Force
    $pathOriginal = $env:Path
    $env:Path = $pastaDeProgramasDoWindows + [IO.Path]::PathSeparator + $env:Path

    $outraEdicao = 'Desktop'
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        $outraEdicao = 'Core'
    }

    $caminhoDoExecutavel = New-ExecutavelDeShimDeTeste -Pasta (Join-Path $TestDrive 'executavel')
    $pastaDosShims = Join-Path $TestDrive 'shims'
    $pastaDosShimsDaOutraEdicao = Join-Path $TestDrive 'shims-da-outra-edicao'
    $null = New-Item -ItemType Directory -Path $pastaDosShims, $pastaDosShimsDaOutraEdicao
    $parametrosDosShims = @{
        Pasta               = $pastaDosShims
        PastaDaOutraEdicao  = $pastaDosShimsDaOutraEdicao
        OutraEdicao         = $outraEdicao
        CaminhoDoPowerShell = (Get-Process -Id $PID).Path
        Distribuicao        = $nomeDaDistribuicao
        CaminhoDoExecutavel = $caminhoDoExecutavel
    }
    InModuleScope WinPlaybook -Parameters $parametrosDosShims {
        $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao
        Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = $raizDeMontagem }
        foreach ($comando in Get-ComandoDoAnsible -Distribuicao $Distribuicao) {
            New-ShimDeComando -Nome $comando -Pasta $Pasta -CaminhoDoPowerShell $CaminhoDoPowerShell -PastaDoModulo (Get-PastaDoModulo) -CaminhoDoExecutavel $CaminhoDoExecutavel
        }
        New-ShimDeComando -Nome 'ansible-playbook' -Pasta $PastaDaOutraEdicao -CaminhoDoPowerShell (Get-CaminhoDoPowerShell -Edicao $OutraEdicao) -PastaDoModulo (Get-PastaDoModulo) -CaminhoDoExecutavel $CaminhoDoExecutavel
    }
    $env:Path = $pathOriginal

    $projeto = Join-Path $TestDrive 'projeto'
    Copy-Item (Join-Path $PSScriptRoot '../data/projects/ola') $projeto -Recurse
    Push-Location $projeto
}

AfterAll {
    Pop-Location
    Remove-Module WinPlaybook
    $env:LOCALAPPDATA = $localAppDataOriginal
}

Describe 'Shim' {
    Context 'quando os shims vêm dos comandos do ambiente do Ansible' {
        It 'cria o shim do <_>' -ForEach @('ansible-playbook', 'ansible-lint', 'ansible-galaxy') {
            Test-Path -LiteralPath (Join-Path $pastaDosShims "$_.ps1") | Should-BeTrue
        }

        It 'não cria shim para o <_>, que não é do ambiente do Ansible' -ForEach @('uv', 'uvx') {
            Test-Path -LiteralPath (Join-Path $pastaDosShims "$_.ps1") | Should-BeFalse
        }
    }

    Context 'quando é chamado pelo PowerShell' {
        It 'executa o playbook' {
            $saida = & (Join-Path $pastaDosShims 'ansible-playbook.ps1') site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }

        It 'passa variáveis extras em JSON sem mudança' {
            $saida = & (Join-Path $pastaDosShims 'ansible.ps1') localhost -m ansible.builtin.debug -a 'msg={{ saudacao }}' -e '{"saudacao": "oi mundo"}' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*"msg": "oi mundo"*'
        }
    }

    Context 'quando é chamado por outro programa' {
        It 'executa o playbook' {
            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims 'ansible-playbook.exe') -Argumentos 'site.yml'

            $resultado.CodigoDeSaida | Should-Be 0 -Because $resultado.Saida
            $resultado.Saida | Should-BeLikeString '*oi do WinPlaybook*'
        }

        It 'passa variáveis extras em JSON sem mudança' {
            $argumentos = 'localhost -m ansible.builtin.debug -a "msg={{ saudacao }}" -e "{\"saudacao\": \"oi mundo\"}"'

            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims 'ansible.exe') -Argumentos $argumentos

            $resultado.CodigoDeSaida | Should-Be 0 -Because $resultado.Saida
            $resultado.Saida | Should-BeLikeString '*"msg": "oi mundo"*'
        }

        It 'propaga o código de saída do comando' {
            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims 'ansible-playbook.exe') -Argumentos 'inexistente.yml'

            $resultado.CodigoDeSaida | Should-Be 1 -Because $resultado.Saida
        }
    }

    Context 'quando o executável abre a outra edição do PowerShell' {
        It 'executa o playbook com o módulo da pasta onde ele está' {
            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShimsDaOutraEdicao 'ansible-playbook.exe') -Argumentos 'site.yml'

            $resultado.CodigoDeSaida | Should-Be 0 -Because $resultado.Erro
            $resultado.Saida | Should-BeLikeString '*oi do WinPlaybook*'
        }
    }

    Context 'quando o Path do Windows tem um programa ansible' {
        It 'não cria shim para ele' {
            $nomesDosShims = (Get-ChildItem -LiteralPath $pastaDosShims -Filter '*.ps1').BaseName

            $nomesDosShims | Should-NotContainCollection 'ansible-windows.exe'
        }
    }
}
