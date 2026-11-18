BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDoLog' {
    It 'devolve o arquivo do dia na pasta logs da configuração' {
        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { 'C:\Configuracao' }

        $caminho = InModuleScope WinPlaybook { Get-CaminhoDoLog }

        $caminho | Should-Be "C:\Configuracao\logs\winplaybook-$((Get-Date).ToString('yyyy-MM-dd')).log"
    }
}
