BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-AnsibleCommand' {
    BeforeAll {
        Mock Get-ImageReference -ModuleName WinPlaybook { 'winplaybook:mock' }
    }

    Context 'when the image lists its commands' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'python3', 'ansible-playbook', 'ansible', 'ansible-lint', 'ansible', 'pip'
            }
        }

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

    Context 'when docker fails' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook { $global:LASTEXITCODE = 125 }
        }

        It 'reports the image it could not run' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand } } | Should-Throw -ExceptionMessage '*winplaybook:mock*'
        }
    }

    Context 'when the image has no ansible commands' {
        BeforeAll {
            Mock docker -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'python3', 'pip'
            }
        }

        It 'reports that the image is not usable' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand } } | Should-Throw -ExceptionMessage '*no ansible commands*'
        }
    }
}
