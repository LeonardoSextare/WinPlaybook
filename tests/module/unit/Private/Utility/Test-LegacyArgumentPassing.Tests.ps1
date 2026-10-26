BeforeDiscovery {
    $hasModernArgumentPassing = $PSVersionTable.PSVersion -ge [version] '7.3'
}

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originalArgumentPassing = Get-Variable -Name 'PSNativeCommandArgumentPassing' -Scope Global -ValueOnly -ErrorAction SilentlyContinue
}

AfterAll {
    Set-Variable -Name 'PSNativeCommandArgumentPassing' -Scope Global -Value $originalArgumentPassing -ErrorAction SilentlyContinue
    Remove-Module WinPlaybook
}

Describe 'Test-LegacyArgumentPassing' {
    Context 'when PowerShell is older than 7.3' -Skip:$hasModernArgumentPassing {
        It 'returns true' {
            $result = InModuleScope WinPlaybook { Test-LegacyArgumentPassing }

            $result | Should-BeTrue
        }
    }

    Context 'when PowerShell 7.3 or newer uses <Style> argument passing' -Skip:(-not $hasModernArgumentPassing) -ForEach @(
        @{ Style = 'Windows'; Expected = $false }
        @{ Style = 'Standard'; Expected = $false }
        @{ Style = 'Legacy'; Expected = $true }
    ) {
        BeforeAll {
            $global:PSNativeCommandArgumentPassing = $Style
        }

        It 'returns <Expected>' {
            $result = InModuleScope WinPlaybook { Test-LegacyArgumentPassing }

            $result | Should-Be $Expected
        }
    }
}
