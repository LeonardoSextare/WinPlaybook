BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDoSshdDoWinPlaybook' {
    It 'devolve a pasta WinPlaybook\ssh de ProgramData' {
        InModuleScope WinPlaybook { Get-PastaDoSshdDoWinPlaybook } | Should-Be (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'WinPlaybook\ssh')
    }
}
