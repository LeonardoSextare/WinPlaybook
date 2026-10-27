BeforeAll {
    . (Join-Path $PSScriptRoot '../../shared/helpers/Docker.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $originalImage = $env:WINPLAYBOOK_IMAGE
    $env:WINPLAYBOOK_IMAGE = Build-TestImage

    $originalAnsibleHome = $env:WINPLAYBOOK_ANSIBLE_HOME
    $testAnsibleHome = Join-Path $TestDrive 'ansible-home'
    $env:WINPLAYBOOK_ANSIBLE_HOME = $testAnsibleHome

    $helloProject = Join-Path $PSScriptRoot '../../shared/data/projects/hello'
    $lintViolationProject = Join-Path $PSScriptRoot '../../shared/data/projects/lint-violation'
    $localCollectionProject = Join-Path $PSScriptRoot '../data/projects/local-collection'
}

AfterAll {
    Remove-Module WinPlaybook
    $env:WINPLAYBOOK_IMAGE = $originalImage
    $env:WINPLAYBOOK_ANSIBLE_HOME = $originalAnsibleHome
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

    Context 'when the Ansible folder of Windows does not exist' {
        BeforeAll {
            $newAnsibleHome = Join-Path $TestDrive 'new-ansible-home'
            $env:WINPLAYBOOK_ANSIBLE_HOME = $newAnsibleHome
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            $env:WINPLAYBOOK_ANSIBLE_HOME = $testAnsibleHome
        }

        It 'creates the folder' {
            $output = Invoke-WinPlaybook ansible --version 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            Test-Path -LiteralPath $newAnsibleHome -PathType Container | Should-BeTrue
        }
    }

    Context 'when a collection was installed in a previous run' {
        BeforeAll {
            $env:WINPLAYBOOK_ANSIBLE_HOME = Join-Path $TestDrive 'collection-ansible-home'
            $project = Join-Path $TestDrive 'local-collection'
            Copy-Item $localCollectionProject $project -Recurse
            Push-Location $project

            $installOutput = Invoke-WinPlaybook ansible-galaxy collection install ./demo/test 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install the test collection: $installOutput"
            }
        }

        AfterAll {
            Pop-Location
            $env:WINPLAYBOOK_ANSIBLE_HOME = $testAnsibleHome
        }

        It 'finds the collection' {
            $output = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from the demo.test collection*'
        }
    }
}
