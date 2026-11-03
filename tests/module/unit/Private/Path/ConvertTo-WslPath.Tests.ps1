BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-WslPath' {
    Context 'when the path is an absolute Windows path' {
        It 'converts <Path> under <MountRoot> to <Expected>' -ForEach @(
            @{ MountRoot = '/mnt/'; Path = 'C:\repo\site.yml'; Expected = '/mnt/c/repo/site.yml' }
            @{ MountRoot = '/mnt/'; Path = 'C:\repo\playbooks\site.yml'; Expected = '/mnt/c/repo/playbooks/site.yml' }
            @{ MountRoot = '/mnt/'; Path = 'C:/repo/playbooks/site.yml'; Expected = '/mnt/c/repo/playbooks/site.yml' }
            @{ MountRoot = '/mnt/'; Path = 'D:\Repo\Site.yml'; Expected = '/mnt/d/Repo/Site.yml' }
            @{ MountRoot = '/mnt/'; Path = 'C:\'; Expected = '/mnt/c/' }
            @{ MountRoot = '/mnt/'; Path = 'C:\my repo\[x].yml'; Expected = '/mnt/c/my repo/[x].yml' }
            @{ MountRoot = '/mnt'; Path = 'C:\repo'; Expected = '/mnt/c/repo' }
            @{ MountRoot = '/'; Path = 'C:\repo'; Expected = '/c/repo' }
        ) {
            $result = InModuleScope WinPlaybook -Parameters $_ {
                ConvertTo-WslPath -Path $Path -MountRoot $MountRoot
            }

            $result | Should-BeString $Expected -CaseSensitive
        }
    }

    Context 'when the path is not an absolute Windows path' {
        It 'rejects <_>' -ForEach @(
            'site.yml'
            'C:site.yml'
            '\\server\share\site.yml'
        ) {
            {
                InModuleScope WinPlaybook -Parameters @{ Path = $_ } {
                    ConvertTo-WslPath -Path $Path -MountRoot '/mnt/'
                }
            } | Should-Throw -ExceptionMessage '*not an absolute Windows path*'
        }
    }
}
