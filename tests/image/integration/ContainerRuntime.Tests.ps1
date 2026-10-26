BeforeAll {
    . (Join-Path $PSScriptRoot '../../shared/helpers/Docker.ps1')
    $image = Build-TestImage
    $projectsDir = Join-Path $PSScriptRoot '../../shared/data/projects'
}

Describe 'Container runtime' {
    It 'propagates the exit code of the command' {
        $result = Invoke-Container $image -Command 'sh', '-c', 'exit 3'

        $result.ExitCode | Should-Be 3
    }

    Context 'when no command is given' {
        It 'shows the ansible version' {
            $result = Invoke-Container $image

            $result.Output | Should-BeLikeString 'ansible `[core *'
        }
    }

    Context 'when a project is mounted' {
        BeforeAll {
            Copy-Item (Join-Path $projectsDir '*') $TestDrive -Recurse
        }

        It 'runs the playbook' {
            $result = Invoke-Container $image -Project (Join-Path $TestDrive 'hello') -Command 'ansible-playbook', 'site.yml'

            $result.ExitCode | Should-Be 0 -Because $result.Output
            $result.Output | Should-BeLikeString '*hello from WinPlaybook*'
        }

        It 'reports lint violations' {
            $result = Invoke-Container $image -Project (Join-Path $TestDrive 'lint-violation') -Command 'ansible-lint', 'site.yml'

            $result.ExitCode | Should-NotBe 0
            $result.Output | Should-BeLikeString '*fqcn`[action-core`]*'
        }
    }
}
