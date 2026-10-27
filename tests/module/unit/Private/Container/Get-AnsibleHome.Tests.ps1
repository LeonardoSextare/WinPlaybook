BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originalUserFolder = $env:USERPROFILE
    $originalAnsibleHome = $env:ANSIBLE_HOME
}

AfterAll {
    $env:USERPROFILE = $originalUserFolder
    $env:ANSIBLE_HOME = $originalAnsibleHome
    Remove-Module WinPlaybook
}

Describe 'Get-AnsibleHome' {
    BeforeAll {
        $env:USERPROFILE = 'C:\Users\mock'
        $env:ANSIBLE_HOME = $null
    }

    Context 'when ANSIBLE_HOME is not set' {
        It 'returns the .ansible folder in the user folder' {
            $result = InModuleScope WinPlaybook { Get-AnsibleHome }

            $result | Should-Be 'C:\Users\mock\.ansible'
        }
    }

    Context 'when ANSIBLE_HOME is set' {
        BeforeAll {
            $env:ANSIBLE_HOME = 'D:\ansible'
        }

        AfterAll {
            $env:ANSIBLE_HOME = $null
        }

        # Remove -Skip in #23, which adds ANSIBLE_HOME.
        It 'returns the folder from the variable' -Skip {
            $result = InModuleScope WinPlaybook { Get-AnsibleHome }

            $result | Should-Be 'D:\ansible'
        }
    }
}
