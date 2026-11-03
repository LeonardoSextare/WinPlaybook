BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-AnsibleCommand' {
    BeforeAll {
        Mock wsl -ModuleName WinPlaybook {
            $global:LASTEXITCODE = 0
            'python3', 'ansible-playbook', 'ansible', 'ansible-lint', 'ansible', 'pip'
        }
        Mock Test-LegacyArgumentPassing -ModuleName WinPlaybook { $false }
    }

    Context 'when the distribution lists its commands' {
        It 'returns the ansible commands sorted and without repetition' {
            $result = InModuleScope WinPlaybook { Get-AnsibleCommand -Distribution 'Ubuntu' -MountRoot '/mnt/' }

            $result | Should-BeCollection @('ansible', 'ansible-lint', 'ansible-playbook')
        }

        It 'asks a login shell of the distribution' {
            InModuleScope WinPlaybook { Get-AnsibleCommand -Distribution 'Ubuntu' -MountRoot '/mnt/' } | Out-Null

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args[0..4] -join ' ') -eq '--distribution Ubuntu --exec sh -lc'
            }
        }

        It 'passes the mount root, so the script skips the folders of the Windows drives' {
            InModuleScope WinPlaybook { Get-AnsibleCommand -Distribution 'Ubuntu' -MountRoot '/mnt/' } | Out-Null

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $args[-1] -eq '/mnt/'
            }
        }
    }

    Context 'when PowerShell passes arguments to programs in the legacy way' {
        BeforeAll {
            Mock Test-LegacyArgumentPassing -ModuleName WinPlaybook { $true }
        }

        It 'escapes the quotes of the script' {
            InModuleScope WinPlaybook { Get-AnsibleCommand -Distribution 'Ubuntu' -MountRoot '/mnt/' } | Out-Null

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $args[5].Contains('\"$0\"')
            }
        }
    }

    Context 'when wsl fails to list the commands' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
        }

        It 'reports the distribution it could not run' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand -Distribution 'Ubuntu' -MountRoot '/mnt/' } } | Should-Throw -ExceptionMessage '*list the commands of the WSL distribution Ubuntu*'
        }
    }

    Context 'when the distribution has no ansible commands' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'python3', 'pip'
            }
        }

        It 'explains that Ansible is missing in the distribution' {
            { InModuleScope WinPlaybook { Get-AnsibleCommand -Distribution 'Ubuntu' -MountRoot '/mnt/' } } | Should-Throw -ExceptionMessage '*Ubuntu has no ansible commands*Install Ansible*'
        }
    }
}
