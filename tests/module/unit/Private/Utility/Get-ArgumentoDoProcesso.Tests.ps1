BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ArgumentoDoProcesso' {
    It 'devolve os argumentos com que o processo atual foi aberto' {
        $resultado = InModuleScope WinPlaybook { Get-ArgumentoDoProcesso }

        $resultado | Should-BeCollection ([Environment]::GetCommandLineArgs())
    }
}
