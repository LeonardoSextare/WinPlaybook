BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-NomeDoUsuarioDoWindows' {
    It 'devolve o nome do usuário que executa o comando' {
        $nome = InModuleScope WinPlaybook { Get-NomeDoUsuarioDoWindows }

        $nome | Should-Be ([Environment]::UserName)
    }
}
