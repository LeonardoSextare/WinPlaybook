BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Uninstall-WinPlaybookShim' {
    BeforeAll {
        $templatePath = Join-Path $TestDrive 'template.exe'
        Set-Content -LiteralPath $templatePath -Value 'template shim'

        Mock Get-ConfigFolder -ModuleName WinPlaybook { $configFolder }
        Mock Get-ShimTemplatePath -ModuleName WinPlaybook { $templatePath }
        Mock Get-AnsibleCommand -ModuleName WinPlaybook { 'ansible', 'ansible-playbook' }
        Mock Get-PowerShellPath -ModuleName WinPlaybook { 'C:\PowerShell\pwsh.exe' }
        Mock Add-UserPathEntry -ModuleName WinPlaybook { }
        Mock Remove-UserPathEntry -ModuleName WinPlaybook { }
    }

    BeforeEach {
        $configFolder = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $defaultShimFolder = Join-Path $configFolder 'bin'
    }

    Context 'when the shims are in the default folder' {
        BeforeEach {
            Install-WinPlaybookShim | Out-Null
        }

        It 'removes the shim folder' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath $defaultShimFolder | Should-BeFalse
        }

        It 'removes the shim folder from the user Path' {
            Uninstall-WinPlaybookShim

            Should-Invoke Remove-UserPathEntry -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Folder -eq $defaultShimFolder
            }
        }

        It 'removes the settings and the config folder' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath $configFolder | Should-BeFalse
        }
    }

    Context 'when the shims are in a chosen folder' {
        BeforeEach {
            $chosenFolder = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            Install-WinPlaybookShim -Path $chosenFolder | Out-Null
        }

        It 'removes the WinPlaybook folder created inside it' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath (Join-Path $chosenFolder 'WinPlaybook') | Should-BeFalse
        }

        It 'keeps the chosen folder' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath $chosenFolder | Should-BeTrue
        }
    }

    Context 'when called with -WhatIf' {
        BeforeEach {
            Install-WinPlaybookShim | Out-Null
        }

        It 'keeps the shims' {
            Uninstall-WinPlaybookShim -WhatIf

            Test-Path -LiteralPath $defaultShimFolder | Should-BeTrue
        }
    }
}
