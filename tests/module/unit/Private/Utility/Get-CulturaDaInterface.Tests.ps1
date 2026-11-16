BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CulturaDaInterface' {
    It 'devolve o idioma da interface do PowerShell em execução' {
        $resultado = InModuleScope WinPlaybook { Get-CulturaDaInterface }

        $resultado | Should-Be $PSUICulture
    }
}
