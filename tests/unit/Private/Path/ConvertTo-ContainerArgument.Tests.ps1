BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $projectRoot = Join-Path $TestDrive 'project'
    New-Item -ItemType File -Path (Join-Path $projectRoot 'site.yml') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $projectRoot 'playbooks/site.yml') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $projectRoot 'vars/prod.yml') -Force | Out-Null
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-ContainerArgument' {
    Context 'when the argument is not an absolute path' {
        It 'converts <Description>' -ForEach @(
            @{ Description = 'a relative path that starts with .\'; Argument = '.\site.yml'; Expected = './site.yml' }
            @{ Description = 'a relative path with backslashes'; Argument = 'playbooks\site.yml'; Expected = 'playbooks/site.yml' }
            @{ Description = 'a relative path after @'; Argument = '@vars\prod.yml'; Expected = '@vars/prod.yml' }
            @{ Description = 'a relative path after an option and @'; Argument = '--extra-vars=@vars\prod.yml'; Expected = '--extra-vars=@vars/prod.yml' }
        ) {
            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $Argument; Root = $projectRoot } {
                ConvertTo-ContainerArgument -Argument $Argument -ProjectRoot $Root -CurrentFolder $Root
            }

            $result | Should-Be $Expected
        }

        It 'keeps <Description> unchanged' -ForEach @(
            @{ Description = 'a relative path that does not exist'; Argument = 'missing\site.yml' }
            @{ Description = 'a text with a backslash that is not a path'; Argument = 'echo \n' }
            @{ Description = 'an argument without paths'; Argument = '--check' }
            @{ Description = 'an empty argument'; Argument = '' }
        ) {
            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $Argument; Root = $projectRoot } {
                ConvertTo-ContainerArgument -Argument $Argument -ProjectRoot $Root -CurrentFolder $Root
            }

            $result | Should-Be $Argument
        }
    }

    Context 'when the argument is an absolute path inside the project' {
        It 'converts the path to the project folder in the container' {
            $argument = Join-Path $projectRoot 'playbooks/site.yml'

            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $argument; Root = $projectRoot } {
                ConvertTo-ContainerArgument -Argument $Argument -ProjectRoot $Root -CurrentFolder $Root
            }

            $result | Should-Be '/work/playbooks/site.yml'
        }

        It 'converts the path after an option' {
            $argument = '--inventory=' + (Join-Path $projectRoot 'hosts.yml')

            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $argument; Root = $projectRoot } {
                ConvertTo-ContainerArgument -Argument $Argument -ProjectRoot $Root -CurrentFolder $Root
            }

            $result | Should-Be '--inventory=/work/hosts.yml'
        }

        It 'converts the path after @' {
            $argument = '@' + (Join-Path $projectRoot 'vars/prod.yml')

            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $argument; Root = $projectRoot } {
                ConvertTo-ContainerArgument -Argument $Argument -ProjectRoot $Root -CurrentFolder $Root
            }

            $result | Should-Be '@/work/vars/prod.yml'
        }
    }

    Context 'when the argument is an absolute path outside the project' {
        It 'explains that the path is not available in the container' {
            {
                InModuleScope WinPlaybook -Parameters @{ Root = $projectRoot } {
                    ConvertTo-ContainerArgument -Argument 'C:\outside\site.yml' -ProjectRoot $Root -CurrentFolder $Root
                }
            } | Should-Throw -ExceptionMessage '*outside the project root*'
        }
    }
}
