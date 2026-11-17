BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ScriptDoSupervisor' {
    It 'executa o comando que vem nos argumentos depois do próprio script' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script | Should-BeLikeString '*subprocess.Popen(sys.argv`[1:`]*'
    }

    It 'entrega ao comando a entrada que não é um terminal por um pipe próprio' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script | Should-BeLikeString '*if os.isatty(0):*os.pipe()*stdin=entrada*'
    }

    It 'põe as pastas do Path do Windows no fim do PATH' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("os.environ['PATH'] = os.environ.get('PATH', '') + ':' + preparar_path_do_windows(ambiente['pathDoWindows'])") | Should-BeTrue
    }

    It 'não cria o nome sem extensão do Python e do pip, que a detecção de interpretador do Ansible procura' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("NOME_CURTO_RESERVADO = re.compile(r'^(python|pip|py)[0-9.]*$', re.IGNORECASE)") | Should-BeTrue
    }

    It 'traduz os caminhos do Windows do config do ssh numa cópia que o /usr/local/bin/ssh usa' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("destino = os.path.expanduser('~/.cache/winplaybook/ssh_config')") | Should-BeTrue
        $script.Contains("'\n\nMatch all\nInclude /etc/ssh/ssh_config\n'") | Should-BeTrue
    }

    It 'traduz o .gitconfig do Windows numa cópia que o GIT_CONFIG_GLOBAL aponta' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("os.environ['GIT_CONFIG_GLOBAL'] = destino") | Should-BeTrue
        $script.Contains("preparar_config_do_git(ambiente['pathDoWindows'])") | Should-BeTrue
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
