BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-WslMountRoot' {
    Context 'when the distribution translates the C: drive to <DrivePath>' -ForEach @(
        @{ DrivePath = '/mnt/c/'; Expected = '/mnt/' }
        @{ DrivePath = '/c/'; Expected = '/' }
        @{ DrivePath = '/windows/drives/c/'; Expected = '/windows/drives/' }
    ) {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                $DrivePath
            }
        }

        It 'returns <Expected>' {
            $result = InModuleScope WinPlaybook { Get-WslMountRoot -Distribution 'Ubuntu' }

            $result | Should-Be $Expected
        }
    }

    Context 'when the distribution translates the drive' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                '/mnt/c/'
            }
        }

        It 'asks wslpath in that distribution' {
            InModuleScope WinPlaybook { Get-WslMountRoot -Distribution 'Ubuntu' } | Out-Null

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args -join ' ') -eq '--distribution Ubuntu --exec wslpath -a C:\'
            }
        }
    }

    Context 'when wsl fails' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = -1
                '/mnt/c/'
            }
        }

        It 'reports the distribution' {
            { InModuleScope WinPlaybook { Get-WslMountRoot -Distribution 'Ubuntu' } } | Should-Throw -ExceptionMessage '*distribution Ubuntu mounts the Windows drives*'
        }
    }

    Context 'when wslpath returns something that is not a drive folder' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'C:\'
            }
        }

        It 'reports the distribution' {
            { InModuleScope WinPlaybook { Get-WslMountRoot -Distribution 'Ubuntu' } } | Should-Throw -ExceptionMessage '*distribution Ubuntu mounts the Windows drives*'
        }
    }
}
