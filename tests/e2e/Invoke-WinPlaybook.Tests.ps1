BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Docker.ps1')
    $originalImage = $env:WINPLAYBOOK_IMAGE
    $env:WINPLAYBOOK_IMAGE = Build-TestImage
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $helloProject = Join-Path $PSScriptRoot '../data/projects/hello'
}

AfterAll {
    Remove-Module WinPlaybook
    $env:WINPLAYBOOK_IMAGE = $originalImage
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
}
