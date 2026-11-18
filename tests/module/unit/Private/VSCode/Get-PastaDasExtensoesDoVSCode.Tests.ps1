BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDasExtensoesDoVSCode' {
    It 'devolve a pasta .vscode\extensions do perfil do usuário' {
        $pasta = InModuleScope WinPlaybook { Get-PastaDasExtensoesDoVSCode }

        $pasta | Should-Be (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.vscode\extensions')
    }
}
