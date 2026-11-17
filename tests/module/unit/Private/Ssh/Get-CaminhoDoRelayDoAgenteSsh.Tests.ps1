BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDoRelayDoAgenteSsh' {
    It 'devolve o relay na subpasta exe da pasta dos shims' {
        $caminho = InModuleScope WinPlaybook { Get-CaminhoDoRelayDoAgenteSsh -PastaDosShims 'C:\Tools\WinPlaybook\bin' }

        $caminho | Should-Be 'C:\Tools\WinPlaybook\bin\exe\relay-do-agente-ssh.exe'
    }
}
