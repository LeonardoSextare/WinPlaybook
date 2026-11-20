BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Show-AvisoDeAnsibleDoWindowsNaVenv' {
    BeforeEach {
        $projeto = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $subpasta = Join-Path $projeto 'playbooks'
        $null = New-Item -ItemType Directory -Path $subpasta
        Set-Content -LiteralPath (Join-Path $projeto 'pyproject.toml') -Value '[project]'
        Mock Test-SaidaDeErroNoTerminal -ModuleName WinPlaybook { $true }
        Mock Write-LinhaColoridaNoErro -ModuleName WinPlaybook { }
    }

    Context 'quando a .venv do projeto tem um Ansible do Windows' {
        BeforeEach {
            $pastaDosScripts = Join-Path $projeto '.venv\Scripts'
            $null = New-Item -ItemType Directory -Path $pastaDosScripts
            Set-Content -LiteralPath (Join-Path $pastaDosScripts 'ansible-playbook.exe') -Value ''
        }

        It 'avisa em amarelo, com a pasta da .venv e a correção, a partir de uma subpasta' {
            InModuleScope WinPlaybook -Parameters @{ Pasta = $subpasta } { Show-AvisoDeAnsibleDoWindowsNaVenv -PastaAtual $Pasta }

            $venv = Join-Path $projeto '.venv'
            Should-Invoke Write-LinhaColoridaNoErro -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Cor -eq 'Yellow' -and $Texto.Contains($venv) -and $Texto.Contains("sys_platform == 'linux'") }
        }

        It 'não avisa quando o stderr não é o terminal' {
            Mock Test-SaidaDeErroNoTerminal -ModuleName WinPlaybook { $false }

            InModuleScope WinPlaybook -Parameters @{ Pasta = $subpasta } { Show-AvisoDeAnsibleDoWindowsNaVenv -PastaAtual $Pasta }

            Should-NotInvoke Write-LinhaColoridaNoErro -ModuleName WinPlaybook
        }
    }

    Context 'quando a .venv do projeto não tem o Ansible' {
        It 'não avisa' {
            $null = New-Item -ItemType Directory -Path (Join-Path $projeto '.venv\Scripts')

            InModuleScope WinPlaybook -Parameters @{ Pasta = $subpasta } { Show-AvisoDeAnsibleDoWindowsNaVenv -PastaAtual $Pasta }

            Should-NotInvoke Write-LinhaColoridaNoErro -ModuleName WinPlaybook
        }
    }

    Context 'quando a pasta não está num projeto' {
        It 'não avisa' {
            $foraDoProjeto = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory -Path $foraDoProjeto

            InModuleScope WinPlaybook -Parameters @{ Pasta = $foraDoProjeto } { Show-AvisoDeAnsibleDoWindowsNaVenv -PastaAtual $Pasta }

            Should-NotInvoke Write-LinhaColoridaNoErro -ModuleName WinPlaybook
        }
    }
}
