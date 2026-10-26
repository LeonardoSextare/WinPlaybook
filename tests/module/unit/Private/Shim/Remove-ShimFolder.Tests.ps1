BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-ShimFolder' {
    BeforeAll {
        Mock Remove-UserPathEntry -ModuleName WinPlaybook { }
    }

    Context 'when the WinPlaybook folder has only the shims' {
        BeforeAll {
            $toolsFolder = Join-Path $TestDrive 'tools'
            $shimFolder = Join-Path $toolsFolder 'WinPlaybook/bin'
            New-Item -ItemType Directory -Path $shimFolder -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $shimFolder 'ansible.ps1') -Value 'shim'

            InModuleScope WinPlaybook -Parameters @{ Folder = $shimFolder } { Remove-ShimFolder -Folder $Folder }
        }

        It 'removes the shim folder' {
            Test-Path -LiteralPath $shimFolder | Should-BeFalse
        }

        It 'removes the empty WinPlaybook folder' {
            Test-Path -LiteralPath (Join-Path $toolsFolder 'WinPlaybook') | Should-BeFalse
        }

        It 'keeps the folder chosen by the user' {
            Test-Path -LiteralPath $toolsFolder | Should-BeTrue
        }

        It 'removes the shim folder from the user Path' {
            Should-Invoke Remove-UserPathEntry -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Folder -eq $shimFolder
            }
        }
    }

    Context 'when the WinPlaybook folder has other files' {
        BeforeAll {
            $configFolder = Join-Path $TestDrive 'config'
            $shimFolder = Join-Path $configFolder 'bin'
            New-Item -ItemType Directory -Path $shimFolder -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Value '{}'

            InModuleScope WinPlaybook -Parameters @{ Folder = $shimFolder } { Remove-ShimFolder -Folder $Folder }
        }

        It 'keeps the WinPlaybook folder' {
            Test-Path -LiteralPath $configFolder | Should-BeTrue
        }
    }
}
