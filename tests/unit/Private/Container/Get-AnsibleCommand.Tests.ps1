BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-AnsibleCommand' {
    BeforeAll {
        Mock Confirm-DockerEngine -ModuleName WinPlaybook {}
        Mock Get-ImageReference -ModuleName WinPlaybook { 'winplaybook:mock' }
        Mock docker -ModuleName WinPlaybook {
            $global:LASTEXITCODE = 0
            'python3', 'ansible-playbook', 'ansible', 'ansible-lint', 'ansible', 'pip'
        }
    }

    Context 'when the image lists its commands' {
        It 'returns the ansible commands sorted and without repetition' {
            $result = InModuleScope WinPlaybook { Get-AnsibleCommand }

            $result | Should-BeCollection @('ansible', 'ansible-lint', 'ansible-playbook')
        }

        It 'asks a disposable container of the image' {
            InModuleScope WinPlaybook { Get-AnsibleCommand } | Out-Null

            Should-Invoke docker -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args[0..2] -join ' ') -eq 'run --rm winplaybook:mock'
            }
        }
    }

    Context 'when Docker is not ready' {
        BeforeAll {
            Mock Confirm-DockerEngine -ModuleName WinPlaybook { throw 'Docker was not found.' }
        }

        It 'stops before calling docker' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand } } | Should-Throw -ExceptionMessage 'Docker was not found.'

            Should-Invoke docker -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }

    Context 'when the image is already downloaded' {
        It 'does not download it again' {
            InModuleScope WinPlaybook { Get-AnsibleCommand } | Out-Null

            Should-Invoke docker -ModuleName WinPlaybook -Times 0 -Exactly -ParameterFilter { $args[0] -eq 'pull' }
        }
    }

    Context 'when the image is not downloaded yet' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook -ParameterFilter { $args[0] -eq 'image' } { $global:LASTEXITCODE = 1 }
            Mock docker -ModuleName WinPlaybook -ParameterFilter { $args[0] -eq 'pull' } {
                $global:LASTEXITCODE = 0
                'Status: Downloaded newer image for winplaybook:mock'
            }
            Mock Write-Host -ModuleName WinPlaybook {}
        }

        It 'downloads the image' {
            InModuleScope WinPlaybook { Get-AnsibleCommand } | Out-Null

            Should-Invoke docker -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args -join ' ') -eq 'pull winplaybook:mock'
            }
        }

        It 'tells the user which image it is downloading' {
            InModuleScope WinPlaybook { Get-AnsibleCommand } | Out-Null

            Should-Invoke Write-Host -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Object -like '*winplaybook:mock*'
            }
        }

        It 'returns only the ansible commands' {
            $result = InModuleScope WinPlaybook { Get-AnsibleCommand }

            $result | Should-BeCollection @('ansible', 'ansible-lint', 'ansible-playbook')
        }
    }

    Context 'when the image download fails' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook -ParameterFilter { $args[0] -eq 'image' } { $global:LASTEXITCODE = 1 }
            Mock docker -ModuleName WinPlaybook -ParameterFilter { $args[0] -eq 'pull' } { $global:LASTEXITCODE = 1 }
            Mock Write-Host -ModuleName WinPlaybook {}
        }

        It 'reports the image it could not download' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand } } | Should-Throw -ExceptionMessage '*download the image winplaybook:mock*'
        }
    }

    Context 'when docker fails to list the commands' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook -ParameterFilter { $args[0] -eq 'run' } { $global:LASTEXITCODE = 125 }
        }

        It 'reports the image it could not run' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand } } | Should-Throw -ExceptionMessage '*list the commands of the image winplaybook:mock*'
        }
    }

    Context 'when the image has no ansible commands' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook -ParameterFilter { $args[0] -eq 'run' } {
                $global:LASTEXITCODE = 0
                'python3', 'pip'
            }
        }

        It 'reports that the image is not usable' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand } } | Should-Throw -ExceptionMessage '*no ansible commands*'
        }
    }
}
