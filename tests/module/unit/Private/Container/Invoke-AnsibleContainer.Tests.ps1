BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originalUserFolder = $env:USERPROFILE
}

AfterAll {
    $env:USERPROFILE = $originalUserFolder
    Remove-Module WinPlaybook
}

Describe 'Invoke-AnsibleContainer' {
    BeforeAll {
        $projectRoot = Join-Path $TestDrive 'project'
        New-Item -ItemType Directory -Path (Join-Path $projectRoot '.git') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'playbooks') -Force | Out-Null

        $userFolder = Join-Path $TestDrive 'user'
        New-Item -ItemType Directory -Path $userFolder | Out-Null
        $env:USERPROFILE = $userFolder

        Mock Confirm-DockerEngine -ModuleName WinPlaybook {}
        Mock docker -ModuleName WinPlaybook { $args }
        Mock Get-ImageReference -ModuleName WinPlaybook { 'winplaybook:mock' }
        Mock Get-AnsibleHome -ModuleName WinPlaybook { 'C:\Users\mock\.ansible' }
        Mock Test-InteractiveTerminal -ModuleName WinPlaybook { $false }
        Mock Test-LegacyArgumentPassing -ModuleName WinPlaybook { $false }

        Push-Location (Join-Path $projectRoot 'playbooks')
    }

    AfterAll {
        Pop-Location
    }

    It 'runs a disposable container that receives the input' {
        $dockerArguments = InModuleScope WinPlaybook {
            Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
        }

        ($dockerArguments -join ' ') | Should-BeLikeString 'run --rm --interactive *'
    }

    It 'mounts the project root as /work' {
        $dockerArguments = InModuleScope WinPlaybook {
            Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
        }

        ($dockerArguments -join ' ') | Should-BeLikeString "* --volume ${projectRoot}:/work *"
    }

    It 'mounts the Ansible folder of Windows as ~/.ansible' {
        $dockerArguments = InModuleScope WinPlaybook {
            Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
        }

        ($dockerArguments -join ' ') | Should-BeLikeString '* --volume C:\Users\mock\.ansible:/root/.ansible *'
    }

    It 'works in the current folder translated to the container' {
        $dockerArguments = InModuleScope WinPlaybook {
            Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
        }

        ($dockerArguments -join ' ') | Should-BeLikeString '* --workdir /work/playbooks *'
    }

    It 'runs the command with its arguments in the image' {
        $dockerArguments = InModuleScope WinPlaybook {
            Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments '-i', 'inventory.yml', 'site.yml'
        }

        ($dockerArguments -join ' ') | Should-BeLikeString '* winplaybook:mock ansible-playbook -i inventory.yml site.yml'
    }

    It 'runs a command without arguments' {
        $dockerArguments = InModuleScope WinPlaybook {
            Invoke-AnsibleContainer -Command 'ansible'
        }

        ($dockerArguments -join ' ') | Should-BeLikeString '* winplaybook:mock ansible'
    }

    It 'converts the Windows paths of the arguments' {
        $playbookPath = Join-Path $projectRoot 'site.yml'

        $dockerArguments = InModuleScope WinPlaybook -Parameters @{ PlaybookPath = $playbookPath } {
            Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments $PlaybookPath
        }

        ($dockerArguments -join ' ') | Should-BeLikeString '* ansible-playbook /work/site.yml'
    }

    Context 'when the current folder has an ansible.cfg file' {
        BeforeAll {
            $projectConfigPath = Join-Path $projectRoot 'playbooks/ansible.cfg'
            New-Item -ItemType File -Path $projectConfigPath | Out-Null
        }

        AfterAll {
            Remove-Item -LiteralPath $projectConfigPath
        }

        It 'points Ansible to the file' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
            }

            ($dockerArguments -join ' ') | Should-BeLikeString '* --env ANSIBLE_CONFIG=/work/playbooks/ansible.cfg *'
        }
    }

    Context 'when the current folder has no ansible.cfg file' {
        It 'does not point Ansible to a file' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
            }

            ($dockerArguments -join ' ') | Should-NotBeLikeString '*ANSIBLE_CONFIG*'
        }
    }

    Context 'when the user folder has a .ansible.cfg file' {
        BeforeAll {
            $userConfigPath = Join-Path $userFolder '.ansible.cfg'
            New-Item -ItemType File -Path $userConfigPath | Out-Null
        }

        AfterAll {
            Remove-Item -LiteralPath $userConfigPath
        }

        It 'mounts the file as ~/.ansible.cfg' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
            }

            ($dockerArguments -join ' ') | Should-BeLikeString "* --volume ${userConfigPath}:/root/.ansible.cfg *"
        }
    }

    Context 'when the user folder has no .ansible.cfg file' {
        It 'does not mount ~/.ansible.cfg' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
            }

            ($dockerArguments -join ' ') | Should-NotBeLikeString '*/root/.ansible.cfg*'
        }
    }

    Context 'when Docker is not ready' {
        BeforeAll {
            Mock Confirm-DockerEngine -ModuleName WinPlaybook { throw 'Docker was not found.' }
        }

        It 'stops before calling docker' {
            { InModuleScope WinPlaybook { Invoke-AnsibleContainer -Command 'ansible' } } | Should-Throw -ExceptionMessage 'Docker was not found.'

            Should-Invoke docker -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }

    Context 'when the terminal is interactive' {
        BeforeAll {
            Mock Test-InteractiveTerminal -ModuleName WinPlaybook { $true }
        }

        It 'allocates a terminal in the container' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
            }

            $dockerArguments | Should-ContainCollection '--tty'
        }
    }

    Context 'when the terminal is not interactive' {
        It 'does not allocate a terminal in the container' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
            }

            $dockerArguments | Should-NotContainCollection '--tty'
        }
    }

    Context 'when PowerShell passes arguments to programs in the legacy way' {
        BeforeAll {
            Mock Test-LegacyArgumentPassing -ModuleName WinPlaybook { $true }
        }

        It 'escapes the quotes of the arguments' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible' -Arguments '-e', '{"a": 1}'
            }

            $dockerArguments | Should-ContainCollection '{\"a\": 1}'
        }
    }

    Context 'when PowerShell passes arguments to programs in the modern way' {
        It 'keeps the quotes of the arguments' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible' -Arguments '-e', '{"a": 1}'
            }

            $dockerArguments | Should-ContainCollection '{"a": 1}'
        }
    }

    Context 'when the current location is on a PowerShell drive' {
        BeforeAll {
            Push-Location 'TestDrive:/project/playbooks'
        }

        AfterAll {
            Pop-Location
        }

        It 'mounts the real folder of the drive' {
            $dockerArguments = InModuleScope WinPlaybook {
                Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'
            }

            ($dockerArguments -join ' ') | Should-BeLikeString "* --volume ${projectRoot}:/work *"
        }
    }
}
