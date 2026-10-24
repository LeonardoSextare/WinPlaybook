BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originalSessionPath = $env:PATH
}

AfterAll {
    $env:PATH = $originalSessionPath
    Remove-Module WinPlaybook
}

Describe 'Remove-UserPathEntry' {
    BeforeAll {
        Mock Set-UserEnvironmentVariable -ModuleName WinPlaybook { }
    }

    AfterEach {
        $env:PATH = $originalSessionPath
    }

    Context 'when the folder is in the user Path' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { 'C:\Tools;c:\shims\;C:\Other' }
        }

        It 'removes it from the user Path' {
            InModuleScope WinPlaybook { Remove-UserPathEntry -Folder 'C:\Shims' }

            Should-Invoke Set-UserEnvironmentVariable -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Path' -and $Value -eq 'C:\Tools;C:\Other'
            }
        }
    }

    Context 'when the folder is not in the user Path' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { 'C:\Tools;C:\Other' }
        }

        It 'leaves the user Path unchanged' {
            InModuleScope WinPlaybook { Remove-UserPathEntry -Folder 'C:\Shims' }

            Should-NotInvoke Set-UserEnvironmentVariable -ModuleName WinPlaybook
        }
    }

    Context 'when the folder is in the current session' {
        BeforeAll {
            Mock Get-UserEnvironmentVariable -ModuleName WinPlaybook { 'C:\Tools' }
        }

        It 'removes it from the session Path' {
            $env:PATH = 'C:\Shims;C:\Windows'

            InModuleScope WinPlaybook { Remove-UserPathEntry -Folder 'C:\Shims' }

            $env:PATH | Should-Be 'C:\Windows'
        }
    }
}
