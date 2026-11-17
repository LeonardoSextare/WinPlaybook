BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDoSshDoUsuario' {
    It 'devolve a pasta .ssh do perfil do usuário' {
        $pasta = InModuleScope WinPlaybook { Get-PastaDoSshDoUsuario }

        $pasta | Should-Be (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.ssh')
    }
}
