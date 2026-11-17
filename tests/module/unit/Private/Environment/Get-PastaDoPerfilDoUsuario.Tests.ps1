BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDoPerfilDoUsuario' {
    It 'devolve a pasta do perfil do usuário' {
        $pasta = InModuleScope WinPlaybook { Get-PastaDoPerfilDoUsuario }

        $pasta | Should-Be ([Environment]::GetFolderPath('UserProfile'))
    }
}
