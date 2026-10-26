BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Confirm-DockerEngine' {
    Context 'when Docker is not installed' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'docker' } {}
        }

        It 'explains how to install Docker Desktop' {
            { InModuleScope WinPlaybook { Confirm-DockerEngine } } | Should-Throw -ExceptionMessage '*install Docker Desktop (https://docs.docker.com/*'
        }
    }

    Context 'when the Docker engine does not respond' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook { $global:LASTEXITCODE = 1 }
        }

        It 'asks to start Docker Desktop' {
            { InModuleScope WinPlaybook { Confirm-DockerEngine } } | Should-Throw -ExceptionMessage '*Start Docker Desktop*'
        }
    }

    Context 'when the Docker engine responds' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                '29.0.0'
            }
        }

        It 'returns nothing' {
            $result = InModuleScope WinPlaybook { Confirm-DockerEngine }

            $result | Should-BeNull
        }
    }
}
