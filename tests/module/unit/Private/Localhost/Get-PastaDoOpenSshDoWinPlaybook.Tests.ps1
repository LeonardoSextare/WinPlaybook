BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDoOpenSshDoWinPlaybook' {
    It 'fica em ProgramData, na pasta do WinPlaybook' {
        $pasta = InModuleScope WinPlaybook { Get-PastaDoOpenSshDoWinPlaybook }

        $pasta | Should-Be (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'WinPlaybook\openssh')
    }
}
