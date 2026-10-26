Describe 'Remove-UserPathEntry' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
        . (Join-Path $PSScriptRoot '../../../helpers/Environment.ps1')
        Clear-TestVariable
    }

    AfterAll {
        Clear-TestVariable
        Remove-Module WinPlaybook
    }

    BeforeEach {
        $variableName = New-TestVariableName
    }

    AfterEach {
        Remove-TestVariable -Name $variableName
    }

    Context 'when the folder is in the user variable' {
        It 'removes it and keeps the other entries' {
            Set-TestUserVariable -Name $variableName -Value 'C:\Tools;c:\shims\;%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Remove-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Value | Should-Be 'C:\Tools;%USERPROFILE%\bin'
        }

        It 'keeps the variable as an expandable string' {
            Set-TestUserVariable -Name $variableName -Value 'C:\Shims;%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Remove-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Kind | Should-Be 'ExpandString'
        }
    }

    Context 'when the folder is the only entry of the user variable' {
        It 'removes the variable' {
            Set-TestUserVariable -Name $variableName -Value 'C:\Shims'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Remove-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            Get-TestUserVariable -Name $variableName | Should-BeNull
        }
    }

    Context 'when the folder is not in the user variable' {
        It 'leaves the variable unchanged' {
            Set-TestUserVariable -Name $variableName -Value 'C:\Tools;%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Remove-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Value | Should-Be 'C:\Tools;%USERPROFILE%\bin'
        }
    }

    Context 'when the folder is in the current session' {
        It 'removes it from the session variable' {
            Set-Item -LiteralPath "Env:$variableName" -Value 'C:\Shims;C:\Windows'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Remove-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-Item -LiteralPath "Env:$variableName").Value | Should-Be 'C:\Windows'
        }

        It 'removes the session variable when the folder is its only entry' {
            Set-Item -LiteralPath "Env:$variableName" -Value 'C:\Shims'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Remove-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            Test-Path -LiteralPath "Env:$variableName" | Should-BeFalse
        }
    }
}
