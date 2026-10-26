BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-LegacyNativeArgument' {
    It 'converts <Description>' -ForEach @(
        @{ Description = 'an argument without special characters'; Argument = 'site.yml'; Expected = 'site.yml' }
        @{ Description = 'quotes'; Argument = '{"greeting": "hello world"}'; Expected = '{\"greeting\": \"hello world\"}' }
        @{ Description = 'a backslash before a quote'; Argument = 'a\"b'; Expected = 'a\\\"b' }
        @{ Description = 'a trailing backslash in an argument with spaces'; Argument = 'C:\My Folder\'; Expected = 'C:\My Folder\\' }
        @{ Description = 'a trailing backslash in an argument without spaces'; Argument = 'C:\Folder\'; Expected = 'C:\Folder\' }
        @{ Description = 'an empty argument'; Argument = ''; Expected = '""' }
    ) {
        $result = InModuleScope WinPlaybook -Parameters @{ Argument = $Argument } {
            ConvertTo-LegacyNativeArgument -Argument $Argument
        }

        $result | Should-Be $Expected
    }

    It 'keeps the order of several arguments' {
        $result = InModuleScope WinPlaybook {
            ConvertTo-LegacyNativeArgument -Argument '-e', '{"a": 1}', 'site.yml'
        }

        $result | Should-BeCollection @('-e', '{\"a\": 1}', 'site.yml')
    }
}
