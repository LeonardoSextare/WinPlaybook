BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $variableName = "WINPLAYBOOK_TEST_$([guid]::NewGuid().ToString('N'))"
}

AfterAll {
    [Environment]::SetEnvironmentVariable($variableName, [NullString]::Value, 'User')
    Remove-Module WinPlaybook
}

Describe 'Get-UserEnvironmentVariable' {
    Context 'when the variable is set for the user' {
        BeforeAll {
            [Environment]::SetEnvironmentVariable($variableName, 'user value', 'User')
        }

        It 'returns its value' {
            $result = InModuleScope WinPlaybook -Parameters @{ Name = $variableName } {
                Get-UserEnvironmentVariable -Name $Name
            }

            $result | Should-Be 'user value'
        }
    }
}
