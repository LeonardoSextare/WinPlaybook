BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PatchDaExtensaoAnsible' {
    BeforeDiscovery {
        Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
        $trocas = InModuleScope WinPlaybook { (Get-PatchDaExtensaoAnsible)['26.11.0'] }
    }

    It 'troca em <Arquivo> um trecho por outro diferente' -ForEach $trocas {
        $De | Should-NotBe $Para
    }

    It 'troca só arquivos do language server em CommonJS, que a extensão carrega' -ForEach $trocas {
        $Arquivo | Should-BeLikeString '*.cjs'
    }
}
