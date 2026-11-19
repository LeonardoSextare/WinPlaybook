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

    It 'troca só os arquivos que a extensão carrega: o principal e os do language server em CommonJS' -ForEach $trocas {
        $Arquivo | Should-MatchString '^(dist\\extension\\extension\.js|packages\\ansible-language-server\\dist\\.+\.cjs)$'
    }
}
