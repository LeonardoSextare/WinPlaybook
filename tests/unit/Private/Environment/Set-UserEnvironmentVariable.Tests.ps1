BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $variableName = "WINPLAYBOOK_TEST_$([guid]::NewGuid().ToString('N'))"
}

AfterAll {
    [Environment]::SetEnvironmentVariable($variableName, [NullString]::Value, 'User')
    Remove-Module WinPlaybook
}

Describe 'Set-UserEnvironmentVariable' {
    It 'saves the value for the user' {
        InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
            Set-UserEnvironmentVariable -Name $Name -Value 'user value'
        }

        [Environment]::GetEnvironmentVariable($variableName, 'User') | Should-Be 'user value'
    }

    It 'removes the variable when the value is empty' {
        [Environment]::SetEnvironmentVariable($variableName, 'user value', 'User')

        InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
            Set-UserEnvironmentVariable -Name $Name -Value ''
        }

        [Environment]::GetEnvironmentVariable($variableName, 'User') | Should-BeNull
    }
}
