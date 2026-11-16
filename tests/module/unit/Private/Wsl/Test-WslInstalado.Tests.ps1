BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Test-WslInstalado' {
    Context 'quando o wsl --status funciona' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 0 }
        }

        It 'diz que o WSL está instalado' {
            $resultado = InModuleScope WinPlaybook { Test-WslInstalado }

            $resultado | Should-BeTrue
        }

        It 'pergunta ao wsl pelo --status' {
            $null = InModuleScope WinPlaybook { Test-WslInstalado }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -eq '--status' }
        }
    }

    Context 'quando o wsl.exe existe, mas o WSL não foi instalado' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 1 }
        }

        It 'diz que o WSL não está instalado' {
            $resultado = InModuleScope WinPlaybook { Test-WslInstalado }

            $resultado | Should-BeFalse
        }
    }

    Context 'quando o Windows não tem o wsl.exe' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'wsl' } { }
        }

        It 'diz que o WSL não está instalado' {
            $resultado = InModuleScope WinPlaybook { Test-WslInstalado }

            $resultado | Should-BeFalse
        }
    }
}
