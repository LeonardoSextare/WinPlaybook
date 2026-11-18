BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDoRelayDeRede' {
    It 'devolve o relay na subpasta exe da pasta dos shims' {
        $caminho = InModuleScope WinPlaybook { Get-CaminhoDoRelayDeRede -PastaDosShims 'C:\Tools\WinPlaybook\bin' }

        $caminho | Should-Be 'C:\Tools\WinPlaybook\bin\exe\relay-de-rede.exe'
    }
}
