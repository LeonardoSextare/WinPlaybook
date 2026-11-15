BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')

    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste

    $localAppDataOriginal = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'

    $psModulePathOriginal = $env:PSModulePath
    $pastaDosModulos = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../module'))
    $env:PSModulePath = $pastaDosModulos + [IO.Path]::PathSeparator + $env:PSModulePath
    Import-Module (Join-Path $pastaDosModulos 'WinPlaybook/WinPlaybook.psd1') -Force

    $pastaDeProgramasDoWindows = Join-Path $TestDrive 'programas-do-windows'
    $null = New-Item -ItemType File -Path (Join-Path $pastaDeProgramasDoWindows 'ansible-windows.exe') -Force
    $pathOriginal = $env:Path
    $env:Path = $pastaDeProgramasDoWindows + [IO.Path]::PathSeparator + $env:Path

    $pastaDosShims = Join-Path $TestDrive 'shims'
    $null = New-Item -ItemType Directory -Path $pastaDosShims
    $parametrosDosShims = @{ Pasta = $pastaDosShims; CaminhoDoPowerShell = (Get-Process -Id $PID).Path; Distribuicao = $nomeDaDistribuicao }
    InModuleScope WinPlaybook -Parameters $parametrosDosShims {
        $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao
        Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = $raizDeMontagem }
        foreach ($comando in Get-ComandoDoAnsible -Distribuicao $Distribuicao -RaizDeMontagem $raizDeMontagem) {
            New-ShimDeComando -Nome $comando -Pasta $Pasta -CaminhoDoPowerShell $CaminhoDoPowerShell
        }
    }
    $env:Path = $pathOriginal

    $projeto = Join-Path $TestDrive 'projeto'
    Copy-Item (Join-Path $PSScriptRoot '../data/projects/ola') $projeto -Recurse
    Push-Location $projeto
}

AfterAll {
    Pop-Location
    Remove-Module WinPlaybook
    $env:PSModulePath = $psModulePathOriginal
    $env:LOCALAPPDATA = $localAppDataOriginal
}

Describe 'Shim' {
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

    Context 'quando o Path do Windows tem um programa ansible' {
        It 'não cria shim para ele' {
            $nomesDosShims = (Get-ChildItem -LiteralPath $pastaDosShims -Filter '*.ps1').BaseName

            $nomesDosShims | Should-NotContainCollection 'ansible-windows.exe'
        }
    }
}
