Describe 'Send-AvisoDeMudancaNoAmbiente' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    }

    AfterAll {
        Remove-Module WinPlaybook
    }

    It 'avisa os programas abertos sem escrever nada' {
        $resultado = InModuleScope WinPlaybook { Send-AvisoDeMudancaNoAmbiente }

        $resultado | Should-BeNull
    }

    It 'avisa de novo na mesma sessão' {
        InModuleScope WinPlaybook { Send-AvisoDeMudancaNoAmbiente }

        $resultado = InModuleScope WinPlaybook { Send-AvisoDeMudancaNoAmbiente }

        $resultado | Should-BeNull
    }
}
