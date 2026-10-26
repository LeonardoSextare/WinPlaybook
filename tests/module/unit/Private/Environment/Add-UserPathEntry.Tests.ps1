Describe 'Add-UserPathEntry' {
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

    Context 'when the folder is not in the user variable' {
        It 'puts the folder at the start' {
            Set-TestUserVariable -Name $variableName -Value 'C:\Tools;C:\Other'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Add-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Value | Should-Be 'C:\Shims;C:\Tools;C:\Other'
        }

        It 'keeps the entries that use environment variables' {
            Set-TestUserVariable -Name $variableName -Value '%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Add-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Value | Should-Be 'C:\Shims;%USERPROFILE%\bin'
        }

        It 'saves the variable as an expandable string' {
            Set-TestUserVariable -Name $variableName -Value '%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Add-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Kind | Should-Be 'ExpandString'
        }
    }

    Context 'when the user variable does not exist' {
        It 'creates it with the folder' {
            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Add-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Value | Should-Be 'C:\Shims'
        }
    }

    Context 'when the folder is already in the user variable' {
        It 'leaves the variable unchanged when the entry is <Entry>' -ForEach @(
            @{ Entry = 'c:\shims\'; Folder = 'C:\Shims' }
            @{ Entry = '%TEMP%\winplaybook-shims'; Folder = Join-Path $env:TEMP 'winplaybook-shims' }
        ) {
            Set-TestUserVariable -Name $variableName -Value "C:\Tools;$Entry"

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName; Folder = $Folder } {
                Add-UserPathEntry -Folder $Folder -VariableName $Name
            }

            (Get-TestUserVariable -Name $variableName).Value | Should-Be "C:\Tools;$Entry"
        }
    }

    Context 'when the folder is not in the current session' {
        It 'puts the folder at the start of the session variable' {
            Set-TestUserVariable -Name $variableName -Value 'C:\Shims'
            Set-Item -LiteralPath "Env:$variableName" -Value 'C:\Windows'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Add-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-Item -LiteralPath "Env:$variableName").Value | Should-Be 'C:\Shims;C:\Windows'
        }
    }

    Context 'when the folder is already in the current session' {
        It 'leaves the session variable unchanged' {
            Set-TestUserVariable -Name $variableName -Value 'C:\Shims'
            Set-Item -LiteralPath "Env:$variableName" -Value 'C:\Windows;C:\Shims'

            InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Add-UserPathEntry -Folder 'C:\Shims' -VariableName $Name
            }

            (Get-Item -LiteralPath "Env:$variableName").Value | Should-Be 'C:\Windows;C:\Shims'
        }
    }
}
