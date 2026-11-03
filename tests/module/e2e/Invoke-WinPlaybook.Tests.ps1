BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $wslDistributionName = Initialize-TestWslDistribution

    $originalLocalAppData = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'
    InModuleScope WinPlaybook -Parameters @{ Distribution = $wslDistributionName } {
        Save-Setting -Settings @{ WslDistribution = $Distribution; WslMountRoot = (Get-WslMountRoot -Distribution $Distribution) }
    }

    $helloProject = Join-Path $PSScriptRoot '../data/projects/hello'
    $lintViolationProject = Join-Path $PSScriptRoot '../data/projects/lint-violation'
    $projectConfigProject = Join-Path $PSScriptRoot '../data/projects/project-config'
}

AfterAll {
    Remove-Module WinPlaybook
    $env:LOCALAPPDATA = $originalLocalAppData
}

Describe 'Invoke-WinPlaybook' {
    Context 'when called from the project folder' {
        BeforeAll {
            $project = Join-Path $TestDrive 'project'
            Copy-Item $helloProject $project -Recurse
            Push-Location $project
        }

        AfterAll {
            Pop-Location
        }

        It 'runs the playbook' {
            $output = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from WinPlaybook*'
        }

        It 'propagates the exit code of the command' {
            $output = Invoke-WinPlaybook sh -c 'exit 3' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 3 -Because $output
        }

        It 'passes the arguments without a shell reading them' {
            $output = Invoke-WinPlaybook printf '%s|' '$HOME' '*' 'a b' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*$HOME|`*|a b|*'
        }

        It 'accepts a relative Windows path' {
            $output = Invoke-WinPlaybook ansible-playbook .\site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from WinPlaybook*'
        }

        It 'accepts an absolute Windows path inside the project' {
            $output = Invoke-WinPlaybook ansible-playbook (Join-Path $project 'site.yml') 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from WinPlaybook*'
        }

        Context 'when the caller stops on errors' {
            BeforeAll {
                $originalErrorAction = $global:ErrorActionPreference
                $global:ErrorActionPreference = 'Stop'
            }

            AfterAll {
                $global:ErrorActionPreference = $originalErrorAction
            }

            It 'keeps running when the command writes to stderr' {
                $output = Invoke-WinPlaybook sh -c 'echo warning >&2; echo finished' 2>&1 | Out-String

                $LASTEXITCODE | Should-Be 0 -Because $output
                $output | Should-BeLikeString '*finished*'
            }
        }
    }

    Context 'when called from a subfolder of a repository' {
        BeforeAll {
            $repository = Join-Path $TestDrive 'repository'
            Copy-Item $helloProject $repository -Recurse
            New-Item -ItemType Directory -Path (Join-Path $repository '.git') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $repository 'playbooks') -Force | Out-Null
            Push-Location (Join-Path $repository 'playbooks')
        }

        AfterAll {
            Pop-Location
        }

        It 'reaches files above the current folder' {
            $output = Invoke-WinPlaybook ansible-playbook ../site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from WinPlaybook*'
        }
    }

    Context 'when the playbook is outside the current folder' {
        BeforeAll {
            $project = Join-Path $TestDrive 'outside-project'
            Copy-Item $helloProject $project -Recurse
            $otherFolder = Join-Path $TestDrive 'other folder'
            New-Item -ItemType Directory -Path $otherFolder | Out-Null
            Push-Location $otherFolder
        }

        AfterAll {
            Pop-Location
        }

        It 'accepts its absolute Windows path' {
            $output = Invoke-WinPlaybook ansible-playbook (Join-Path $project 'site.yml') 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from WinPlaybook*'
        }
    }

    Context 'when the project has lint violations' {
        BeforeAll {
            $project = Join-Path $TestDrive 'lint-violation'
            Copy-Item $lintViolationProject $project -Recurse
            Push-Location $project
        }

        AfterAll {
            Pop-Location
        }

        It 'reports the violations' {
            $output = Invoke-WinPlaybook ansible-lint site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-NotBe 0 -Because $output
            $output | Should-BeLikeString '*fqcn`[action-core`]*'
        }
    }

    Context 'when the ansible.cfg of the project sets a relative collections path' {
        BeforeAll {
            $project = Join-Path $TestDrive 'project-config'
            Copy-Item $projectConfigProject $project -Recurse
            Push-Location $project
        }

        AfterAll {
            Pop-Location
        }

        It 'finds the collections relative to the file' {
            Set-ItResult -Skipped -Because 'Ansible ignores the ansible.cfg of world-writable folders, such as the Windows drives in WSL, until #33'

            $output = Invoke-WinPlaybook ansible-playbook playbooks/site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from the demo.test collection*'
        }
    }

    Context 'when the command is not in the distribution' {
        BeforeAll {
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
        }

        It 'explains that the command is missing' {
            $output = Invoke-WinPlaybook winplaybook-missing-command 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 127 -Because $output
            $output | Should-BeLikeString '*winplaybook-missing-command was not found in the WSL distribution*'
        }

        It 'refuses the program of Windows with the same name' {
            $output = Invoke-WinPlaybook cmd.exe /c exit 0 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 127 -Because $output
            $output | Should-BeLikeString '*cmd.exe is not in the WSL distribution, only on Windows*'
        }
    }
}
