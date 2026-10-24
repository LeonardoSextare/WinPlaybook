BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originalImage = $env:WINPLAYBOOK_IMAGE
}

AfterAll {
    $env:WINPLAYBOOK_IMAGE = $originalImage
    Remove-Module WinPlaybook
}

Describe 'Get-ImageReference' {
    Context 'when WINPLAYBOOK_IMAGE is not set' {
        BeforeAll {
            $env:WINPLAYBOOK_IMAGE = $null
        }

        It 'returns the published image of the supported major version' {
            $result = InModuleScope WinPlaybook { Get-ImageReference }

            $result | Should-Be 'ghcr.io/leonardosextare/winplaybook:0'
        }
    }

    Context 'when WINPLAYBOOK_IMAGE is set' {
        BeforeAll {
            $env:WINPLAYBOOK_IMAGE = 'registry.example.com/winplaybook:0.1.3'
        }

        It 'returns the image from the variable' {
            $result = InModuleScope WinPlaybook { Get-ImageReference }

            $result | Should-Be 'registry.example.com/winplaybook:0.1.3'
        }
    }
}
