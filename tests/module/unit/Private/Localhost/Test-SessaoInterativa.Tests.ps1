BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Test-SessaoInterativa' {
    It 'diz se a sessão é interativa e a entrada vem do teclado' {
        InModuleScope WinPlaybook { Test-SessaoInterativa } | Should-Be ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected)
    }
}
