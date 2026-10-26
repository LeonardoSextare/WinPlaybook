BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-ContainerPath' {
    Context 'when the path is inside the root' {
        It 'converts <Path> under <Root> to <Expected>' -ForEach @(
            @{ Root = 'C:\repo'; Path = 'C:\repo'; Expected = '/work' }
            @{ Root = 'C:\repo'; Path = 'C:\repo\'; Expected = '/work' }
            @{ Root = 'C:\repo'; Path = 'c:\REPO'; Expected = '/work' }
            @{ Root = 'C:\repo'; Path = 'C:\repo\site.yml'; Expected = '/work/site.yml' }
            @{ Root = 'C:\repo'; Path = 'C:\repo\playbooks\site.yml'; Expected = '/work/playbooks/site.yml' }
            @{ Root = 'C:\repo'; Path = 'C:/repo/playbooks/site.yml'; Expected = '/work/playbooks/site.yml' }
            @{ Root = 'C:\repo'; Path = 'c:\REPO\Site.yml'; Expected = '/work/Site.yml' }
            @{ Root = 'C:\repo\'; Path = 'C:\repo\site.yml'; Expected = '/work/site.yml' }
        ) {
            $result = InModuleScope WinPlaybook -Parameters $_ {
                ConvertTo-ContainerPath -Path $Path -Root $Root
            }

            $result | Should-Be $Expected
        }
    }

    Context 'when the path is outside the root' {
        It 'rejects <_>' -ForEach @(
            'C:\other\site.yml'
            'C:\repository\site.yml'
            'D:\repo\site.yml'
        ) {
            {
                InModuleScope WinPlaybook -Parameters @{ Path = $_ } {
                    ConvertTo-ContainerPath -Path $Path -Root 'C:\repo'
                }
            } | Should-Throw -ExceptionMessage '*outside the project root*'
        }
    }
}
