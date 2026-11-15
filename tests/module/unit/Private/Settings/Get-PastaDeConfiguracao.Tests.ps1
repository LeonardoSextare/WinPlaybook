BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDeConfiguracao' {
    It 'devolve a pasta WinPlaybook nos dados locais dos aplicativos' {
        $esperado = Join-Path $env:LOCALAPPDATA 'WinPlaybook'

        $resultado = InModuleScope WinPlaybook { Get-PastaDeConfiguracao }

        $resultado | Should-Be $esperado
    }
}
