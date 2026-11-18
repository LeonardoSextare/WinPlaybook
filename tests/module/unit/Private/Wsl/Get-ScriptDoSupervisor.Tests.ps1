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

    It 'usa o notepad.exe como editor do ansible-vault quando o Windows não define um' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("if os.path.basename(sys.argv[1]) == 'ansible-vault' and not os.environ.get('EDITOR') and not os.environ.get('VISUAL'):") | Should-BeTrue
    }

    It 'aponta as variáveis de certificados para o pacote que junta os do Debian e os do Windows' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("VARIAVEIS_DE_CERTIFICADOS = ('SSL_CERT_FILE', 'REQUESTS_CA_BUNDLE', 'CURL_CA_BUNDLE', 'GIT_SSL_CAINFO')") | Should-BeTrue
        $script.Contains("preparar_certificados(ambiente['certificadosDoWindows'])") | Should-BeTrue
    }

    It 'executa o comando no ambiente do projeto que declara o Ansible num pyproject.toml' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("PACOTES_DO_ANSIBLE = ('ansible', 'ansible-core')") | Should-BeTrue
        $script.Contains("subprocess.run([UV, 'sync', '--quiet', '--project', projeto]") | Should-BeTrue
        $script.Contains("preparar_ambiente_do_projeto(ambiente.get('comandosDoProjeto'))") | Should-BeTrue
    }

    It 'grava a lista dos comandos do ambiente do projeto, sem os do próprio Python' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("COMANDO_DO_AMBIENTE_PYTHON = re.compile(r'^(python[0-9.]*|pip[0-9.]*|pydoc[0-9.]*|activate.*|deactivate)$')") | Should-BeTrue
        $script.Contains('listar_comandos_do_projeto(ambiente_do_projeto, caminho_da_lista_de_comandos)') | Should-BeTrue
    }

    It 'leva ao localhost do Windows as conexões ao localhost da distribuição, pelo relay de rede' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("NFT_DA_PONTE = '/usr/local/lib/winplaybook/nft'") | Should-BeTrue
        $script.Contains('ip daddr 127.0.0.1 tcp dport @portas_do_windows redirect to :47999') | Should-BeTrue
        $script.Contains("iniciar_ponte_de_rede(ambiente.get('relayDeRede'))") | Should-BeTrue
    }

    It 'começa o comando depois que a ponte para o localhost do Windows aplica as portas' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains('ponte_pronta.wait(5)') | Should-BeTrue
    }

    It 'adota os processos que o comando deixa para trás' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script | Should-BeLikeString '*PR_SET_CHILD_SUBREAPER*'
    }

    It 'encerra os processos quando recebe <_>' -ForEach 'SIGHUP', 'SIGTERM' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script | Should-BeLikeString "*signal.signal(signal.$_, guardar_sinal_de_fim)*"
    }

    It 'passa ao Ansible o localhost_windows, com a chave da distribuição' {
        $script = InModuleScope WinPlaybook { Get-ScriptDoSupervisor }

        $script.Contains("CHAVE_DO_LOCALHOST_WINDOWS = os.path.expanduser('~/.config/winplaybook/localhost_windows')") | Should-BeTrue
        $script.Contains("os.environ['WINPLAYBOOK_LOCALHOST_WINDOWS'] = json.dumps(") | Should-BeTrue
    }
}
