BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Invoke-WslCommand' {
    BeforeAll {
        $projectFolder = Join-Path $TestDrive 'project'
        New-Item -ItemType Directory -Path (Join-Path $projectFolder 'playbooks') -Force | Out-Null

        Mock wsl -ModuleName WinPlaybook { $args }
        Mock Get-Setting -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/' } }
        Mock Test-LegacyArgumentPassing -ModuleName WinPlaybook { $false }

        Push-Location $projectFolder
    }

    AfterAll {
        Pop-Location
    }

    It 'runs in the distribution chosen at install' {
        $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible-playbook' -Arguments 'site.yml' }

        ($wslArguments[0..1] -join ' ') | Should-Be '--distribution Ubuntu'
    }

    It 'starts in the current folder' {
        $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible-playbook' -Arguments 'site.yml' }

        ($wslArguments[2..3] -join ' ') | Should-Be "--cd $projectFolder"
    }

    It 'runs a login shell without reading the arguments as shell code' {
        $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible-playbook' -Arguments 'site.yml' }

        ($wslArguments[4..6] -join ' ') | Should-Be '--exec sh -lc'
    }

    It 'passes the mount root, the command and its arguments to the shell script' {
        $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible-playbook' -Arguments '-i', 'inventory.yml', 'site.yml' }

        ($wslArguments[8..12] -join ' ') | Should-Be '/mnt/ ansible-playbook -i inventory.yml site.yml'
    }

    It 'runs a command without arguments' {
        $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible' }

        ($wslArguments[8..($wslArguments.Count - 1)] -join ' ') | Should-Be '/mnt/ ansible'
    }

    It 'converts the Windows paths of the arguments' {
        $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible-playbook' -Arguments 'D:\repo\site.yml' }

        $wslArguments[-1] | Should-Be '/mnt/d/repo/site.yml'
    }

    Context 'when the current location is on a PowerShell drive' {
        BeforeAll {
            Push-Location 'TestDrive:/project/playbooks'
        }

        AfterAll {
            Pop-Location
        }

        It 'starts in the real folder of the drive' {
            $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible-playbook' -Arguments 'site.yml' }

            $wslArguments[3] | Should-Be (Join-Path $projectFolder 'playbooks')
        }
    }

    Context 'when PowerShell passes arguments to programs in the legacy way' {
        BeforeAll {
            Mock Test-LegacyArgumentPassing -ModuleName WinPlaybook { $true }
        }

        It 'escapes the quotes of the arguments' {
            $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible' -Arguments '-e', '{"a": 1}' }

            $wslArguments | Should-ContainCollection '{\"a\": 1}'
        }
    }

    Context 'when PowerShell passes arguments to programs in the modern way' {
        It 'keeps the quotes of the arguments' {
            $wslArguments = InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible' -Arguments '-e', '{"a": 1}' }

            $wslArguments | Should-ContainCollection '{"a": 1}'
        }
    }

    Context 'when no distribution was chosen' {
        BeforeAll {
            Mock Get-Setting -ModuleName WinPlaybook { @{ WslDistribution = $null; WslMountRoot = $null } }
        }

        It 'explains how to choose one' {
            { InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible' } } | Should-Throw -ExceptionMessage '*Install-WinPlaybookShim -Distribution*'
        }

        It 'stops before calling wsl' {
            { InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible' } } | Should-Throw

            Should-Invoke wsl -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }

    Context 'when WSL is not installed' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'wsl' } { }
        }

        It 'explains how to install it' {
            { InModuleScope WinPlaybook { Invoke-WslCommand -Command 'ansible' } } | Should-Throw -ExceptionMessage 'WSL was not found*wsl --install*'
        }
    }
}
