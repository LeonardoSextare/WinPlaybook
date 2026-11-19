BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PacoteDoOpenSsh' {
    It 'aponta para o zip da release oficial da Microsoft, com o SHA256' {
        $pacote = InModuleScope WinPlaybook { Get-PacoteDoOpenSsh }

        $pacote.Url | Should-BeLikeString "https://github.com/PowerShell/Win32-OpenSSH/releases/download/$($pacote.Versao)/OpenSSH-Win64.zip"
        $pacote.Sha256 | Should-MatchString '^[0-9A-F]{64}$'
    }
}
