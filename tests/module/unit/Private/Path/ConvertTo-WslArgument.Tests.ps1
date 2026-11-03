BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $projectFolder = Join-Path $TestDrive 'project'
    New-Item -ItemType File -Path (Join-Path $projectFolder 'site.yml') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $projectFolder 'playbooks/site.yml') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $projectFolder 'vars/prod.yml') -Force | Out-Null
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-WslArgument' {
    Context 'when the argument is not an absolute path' {
        It 'converts <Description>' -ForEach @(
            @{ Description = 'a relative path that starts with .\'; Argument = '.\site.yml'; Expected = './site.yml' }
            @{ Description = 'a relative path with backslashes'; Argument = 'playbooks\site.yml'; Expected = 'playbooks/site.yml' }
            @{ Description = 'a relative path after @'; Argument = '@vars\prod.yml'; Expected = '@vars/prod.yml' }
            @{ Description = 'a relative path after an option and @'; Argument = '--extra-vars=@vars\prod.yml'; Expected = '--extra-vars=@vars/prod.yml' }
        ) {
            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $Argument; Folder = $projectFolder } {
                ConvertTo-WslArgument -Argument $Argument -MountRoot '/mnt/' -CurrentFolder $Folder
            }

            $result | Should-Be $Expected
        }

        It 'keeps <Description> unchanged' -ForEach @(
            @{ Description = 'a relative path that does not exist'; Argument = 'missing\site.yml' }
            @{ Description = 'a text with a backslash that is not a path'; Argument = 'echo \n' }
            @{ Description = 'an argument without paths'; Argument = '--check' }
            @{ Description = 'an empty argument'; Argument = '' }
        ) {
            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $Argument; Folder = $projectFolder } {
                ConvertTo-WslArgument -Argument $Argument -MountRoot '/mnt/' -CurrentFolder $Folder
            }

            $result | Should-Be $Argument
        }
    }

    Context 'when the argument is an absolute path' {
        It 'converts <Description>' -ForEach @(
            @{ Description = 'the path'; Argument = 'C:\repo\playbooks\site.yml'; Expected = '/mnt/c/repo/playbooks/site.yml' }
            @{ Description = 'the path after an option'; Argument = '--inventory=C:\repo\hosts.yml'; Expected = '--inventory=/mnt/c/repo/hosts.yml' }
            @{ Description = 'the path after @'; Argument = '@C:\repo\vars\prod.yml'; Expected = '@/mnt/c/repo/vars/prod.yml' }
            @{ Description = 'the path after an option and @'; Argument = '--extra-vars=@D:\vars\prod.yml'; Expected = '--extra-vars=@/mnt/d/vars/prod.yml' }
        ) {
            $result = InModuleScope WinPlaybook -Parameters @{ Argument = $Argument; Folder = $projectFolder } {
                ConvertTo-WslArgument -Argument $Argument -MountRoot '/mnt/' -CurrentFolder $Folder
            }

            $result | Should-Be $Expected
        }
    }
}
