BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ScriptDoSupervisor' {
    It 'executa o comando que vem nos argumentos depois do próprio script' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script | Should-BeLikeString '*subprocess.Popen(sys.argv`[2:`])*'
    }

    It 'adota os processos que o comando deixa para trás' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script | Should-BeLikeString '*PR_SET_CHILD_SUBREAPER*'
    }

    It 'encerra os processos quando recebe <_>' -ForEach 'SIGHUP', 'SIGTERM' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script | Should-BeLikeString "*signal.signal(signal.$_, guardar_sinal_de_fim)*"
    }
}
