Describe 'Send-EnvironmentChange' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    }

    AfterAll {
        Remove-Module WinPlaybook
    }

    It 'notifies the open programs without output' {
        $result = InModuleScope WinPlaybook { Send-EnvironmentChange }

        $result | Should-BeNull
    }

    It 'can notify again in the same session' {
        InModuleScope WinPlaybook { Send-EnvironmentChange }

        $result = InModuleScope WinPlaybook { Send-EnvironmentChange }

        $result | Should-BeNull
    }
}
