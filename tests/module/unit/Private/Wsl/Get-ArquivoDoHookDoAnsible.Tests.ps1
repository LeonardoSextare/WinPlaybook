BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ArquivoDoHookDoAnsible' {
    It 'devolve as partes do pacote em ordem de nome, com o __init__.py primeiro' {
        $nomes = InModuleScope WinPlaybook { Get-ArquivoDoHookDoAnsible | ForEach-Object { $_.Nome } }

        Should-BeCollection -Actual $nomes -Expected @('__init__.py', 'caminhos.py', 'chaves.py', 'comum.py', 'importacao.py', 'localhost_windows.py', 'saida.py', 'scripts.py')
    }

    It 'converte os caminhos do Windows no os.path.expanduser' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains('os.path.expanduser = expanduser') | Should-BeTrue
    }

    It 'converte os caminhos do Windows no <_> do DataLoader' -ForEach 'path_dwim', 'path_dwim_relative', 'path_dwim_relative_stack' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("data_loader.$_ = $($_)_com_windows") | Should-BeTrue
    }

    It 'protege as barras dos caminhos do Windows sem aspas no inventário INI' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("'ansible.utils.shlex': ajustar_shlex") | Should-BeTrue
    }

    It 'mostra os caminhos do Windows no que os comandos do Ansible escrevem' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains('sys.stdout = mostrar_saida_com_caminhos_do_windows(sys.stdout)') | Should-BeTrue
    }

    It 'mostra os caminhos da distribuição só nos comandos do nó de controle' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("PROGRAMAS_DO_NO_DE_CONTROLE = ('ansible-config', 'ansible-doc', 'ansible-galaxy')") | Should-BeTrue
        $script.Contains("b'//wsl.localhost/' + distribuicao.encode() + caminho") | Should-BeTrue
    }

    It 'tira os CR dos scripts com shebang que o ansible.builtin.script envia' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("'ansible.plugins.action': ajustar_action_base") | Should-BeTrue
    }

    It 'executa pela extensão os scripts das pastas do Windows sem permissão de execução' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("EXTENSOES_DE_SCRIPT = ('.bat', '.cmd', '.exe', '.com', '.ps1', '.py', '.sh')") | Should-BeTrue
        $script.Contains("'ansible.module_utils.common.file': ajustar_arquivo") | Should-BeTrue
        $script.Contains('subprocess.Popen = PopenComScriptsDoWindows') | Should-BeTrue
    }

    It 'ajusta cada módulo pelo próprio carregador, sem mudar o carregador que ele divide com outros' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains('especificacao.loader = CarregadorAjustado(especificacao.loader, self._ajustes[nome])') | Should-BeTrue
    }

    It 'entrega ao ssh uma cópia protegida da chave privada que está numa pasta do Windows' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("'ansible.plugins': ajustar_plugins") | Should-BeTrue
        $script.Contains('os.open(copia, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)') | Should-BeTrue
    }

    It 'usa a raiz de montagem da variável WINPLAYBOOK_MOUNT_ROOT' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/')") | Should-BeTrue
    }

    It 'cria o host localhost_windows implícito, ligado ao Windows pelo SSH' {
        $script = InModuleScope WinPlaybook { -join (Get-ArquivoDoHookDoAnsible | ForEach-Object { [Text.Encoding]::UTF8.GetString($_.Conteudo) }) }

        $script.Contains("HOST_DA_MAQUINA_WINDOWS = 'localhost_windows'") | Should-BeTrue
        $script.Contains("'ansible.inventory.manager': ajustar_gerenciador_de_inventario") | Should-BeTrue
        $script.Contains("'ansible_shell_type': 'cmd'") | Should-BeTrue
    }
}
