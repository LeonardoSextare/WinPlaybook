BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ScriptDosCaminhosDoWindows' {
    It 'converte os caminhos do Windows no os.path.expanduser' {
        $script = InModuleScope WinPlaybook { Get-ScriptDosCaminhosDoWindows }

        $script.Contains('os.path.expanduser = expanduser') | Should-BeTrue
    }

    It 'converte os caminhos do Windows no <_> do DataLoader' -ForEach 'path_dwim', 'path_dwim_relative', 'path_dwim_relative_stack' {
        $script = InModuleScope WinPlaybook { Get-ScriptDosCaminhosDoWindows }

        $script.Contains("data_loader.$_ = $($_)_com_windows") | Should-BeTrue
    }

    It 'protege as barras dos caminhos do Windows sem aspas no inventário INI' {
        $script = InModuleScope WinPlaybook { Get-ScriptDosCaminhosDoWindows }

        $script.Contains("'ansible.utils.shlex': ajustar_shlex") | Should-BeTrue
    }

    It 'mostra os caminhos do Windows no que os comandos do Ansible escrevem' {
        $script = InModuleScope WinPlaybook { Get-ScriptDosCaminhosDoWindows }

        $script.Contains('sys.stdout = mostrar_saida_com_caminhos_do_windows(sys.stdout)') | Should-BeTrue
    }

    It 'usa a raiz de montagem da variável WINPLAYBOOK_MOUNT_ROOT' {
        $script = InModuleScope WinPlaybook { Get-ScriptDosCaminhosDoWindows }

        $script.Contains("os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/')") | Should-BeTrue
    }
}
