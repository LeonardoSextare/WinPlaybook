BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originalTestFolder = $env:WINPLAYBOOK_ANSIBLE_HOME
    $originalAnsibleHome = $env:ANSIBLE_HOME
}

AfterAll {
    $env:WINPLAYBOOK_ANSIBLE_HOME = $originalTestFolder
    $env:ANSIBLE_HOME = $originalAnsibleHome
    Remove-Module WinPlaybook
}

Describe 'Get-AnsibleHome' {
    BeforeAll {
        $env:WINPLAYBOOK_ANSIBLE_HOME = $null
        $env:ANSIBLE_HOME = $null
    }

    Context 'when no variable is set' {
        It 'returns the .ansible folder in the user folder' {
            $expected = Join-Path $env:USERPROFILE '.ansible'

            $result = InModuleScope WinPlaybook { Get-AnsibleHome }

            $result | Should-Be $expected
        }
    }

    Context 'when WINPLAYBOOK_ANSIBLE_HOME is set' {
        BeforeAll {
            $env:WINPLAYBOOK_ANSIBLE_HOME = 'D:\tests\ansible'
        }

        AfterAll {
            $env:WINPLAYBOOK_ANSIBLE_HOME = $null
        }

        It 'returns the folder from the variable' {
            $result = InModuleScope WinPlaybook { Get-AnsibleHome }

            $result | Should-Be 'D:\tests\ansible'
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
