BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originalSessionPath = $env:PATH
}

AfterAll {
    $env:PATH = $originalSessionPath
    Remove-Module WinPlaybook
}

Describe 'Add-UserPathEntry' {
    BeforeAll {
        Mock Set-UserEnvironmentVariable -ModuleName WinPlaybook { }
    }

    AfterEach {
        $env:PATH = $originalSessionPath
    }

    Context 'when the folder is not in the user Path' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { 'C:\Tools;C:\Other' }
        }

        It 'puts the folder at the start of the user Path' {
            InModuleScope WinPlaybook { Add-UserPathEntry -Folder 'C:\Shims' }

            Should-Invoke Set-UserEnvironmentVariable -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Path' -and $Value -eq 'C:\Shims;C:\Tools;C:\Other'
            }
        }
    }

    Context 'when the user Path is empty' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { $null }
        }

        It 'creates the user Path with the folder' {
            InModuleScope WinPlaybook { Add-UserPathEntry -Folder 'C:\Shims' }

            Should-Invoke Set-UserEnvironmentVariable -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Path' -and $Value -eq 'C:\Shims'
            }
        }
    }

    Context 'when the folder is already in the user Path' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { 'C:\Tools;c:\shims\' }
        }

        It 'leaves the user Path unchanged' {
            InModuleScope WinPlaybook { Add-UserPathEntry -Folder 'C:\Shims' }

            Should-NotInvoke Set-UserEnvironmentVariable -ModuleName WinPlaybook
        }
    }

    Context 'when the folder is not in the current session' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { 'C:\Shims' }
        }

        It 'puts the folder at the start of the session Path' {
            $env:PATH = 'C:\Windows;C:\Tools'

            InModuleScope WinPlaybook { Add-UserPathEntry -Folder 'C:\Shims' }

            $env:PATH | Should-Be 'C:\Shims;C:\Windows;C:\Tools'
        }
    }

    Context 'when the folder is already in the current session' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { 'C:\Shims' }
        }

        It 'leaves the session Path unchanged' {
            $env:PATH = 'C:\Windows;C:\Shims'

            InModuleScope WinPlaybook { Add-UserPathEntry -Folder 'C:\Shims' }

            $env:PATH | Should-Be 'C:\Windows;C:\Shims'
        }
    }
}
