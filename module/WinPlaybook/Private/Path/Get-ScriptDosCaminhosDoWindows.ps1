function Get-ScriptDosCaminhosDoWindows {
    <#
    .SYNOPSIS
    Devolve o módulo Python que faz o Ansible aceitar caminhos do Windows.

    .DESCRIPTION
    O módulo é carregado quando o Python do Ansible inicia, por um arquivo .pth no ambiente
    dele. Um caminho absoluto do Windows, como C:\infra\files\dado.txt ou C:/infra, vira o
    caminho dele na distribuição (/mnt/c/infra/files/dado.txt) onde o Ansible expande os
    caminhos: no os.path.expanduser, que o Ansible usa nos caminhos do ansible.cfg, das
    chaves SSH e de outros arquivos, e nos path_dwim do DataLoader, que resolvem os arquivos
    de lookups, includes, templates e do copy. Uma lista de caminhos do ansible.cfg, como o
    roles_path, pode separar caminhos do Windows por ponto e vírgula. A raiz de montagem vem da variável
    WINPLAYBOOK_MOUNT_ROOT, e o padrão é /mnt/.

    .EXAMPLE
    $script = Get-ScriptDosCaminhosDoWindows

    Devolve o código Python, para o Install-AnsibleNaDistribuicao gravar no ambiente do Ansible.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $script = @'
import importlib.abc
import importlib.util
import os
import re
import sys

CAMINHO_DO_WINDOWS = re.compile(r'^[A-Za-z]:[\\/]')
CAMINHO_DO_WINDOWS_EM_BYTES = re.compile(rb'^[A-Za-z]:[\\/]')
LISTA_COM_CAMINHO_DO_WINDOWS = re.compile(r'(^|;)\s*[A-Za-z]:[\\/]')
expanduser_original = os.path.expanduser


def converter_caminho(caminho):
    raiz = os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/')
    if isinstance(caminho, str) and CAMINHO_DO_WINDOWS.match(caminho):
        return raiz + '/' + caminho[0].lower() + caminho[2:].replace('\\', '/')
    if isinstance(caminho, bytes) and CAMINHO_DO_WINDOWS_EM_BYTES.match(caminho):
        return raiz.encode() + b'/' + caminho[0:1].lower() + caminho[2:].replace(b'\\', b'/')
    return caminho


def expanduser(caminho):
    return expanduser_original(converter_caminho(caminho))


def ajustar_data_loader(data_loader):
    path_dwim = data_loader.path_dwim
    path_dwim_relative = data_loader.path_dwim_relative
    path_dwim_relative_stack = data_loader.path_dwim_relative_stack

    def path_dwim_com_windows(self, given):
        return path_dwim(self, converter_caminho(given))

    def path_dwim_relative_com_windows(self, path, dirname, source, *args, **kwargs):
        return path_dwim_relative(self, path, dirname, converter_caminho(source), *args, **kwargs)

    def path_dwim_relative_stack_com_windows(self, paths, dirname, source, *args, **kwargs):
        return path_dwim_relative_stack(self, paths, dirname, converter_caminho(source), *args, **kwargs)

    data_loader.path_dwim = path_dwim_com_windows
    data_loader.path_dwim_relative = path_dwim_relative_com_windows
    data_loader.path_dwim_relative_stack = path_dwim_relative_stack_com_windows


def ajustar_gerenciador_de_configuracao(modulo):
    ensure_type = modulo.ensure_type

    def ensure_type_com_windows(value, value_type, *args, **kwargs):
        if value_type == 'pathspec' and isinstance(value, str) and LISTA_COM_CAMINHO_DO_WINDOWS.search(value):
            value = ':'.join(converter_caminho(item.strip()) for item in value.split(';'))
        return ensure_type(value, value_type, *args, **kwargs)

    modulo.ensure_type = ensure_type_com_windows


AJUSTES = {
    'ansible.parsing.dataloader': lambda modulo: ajustar_data_loader(modulo.DataLoader),
    'ansible.config.manager': ajustar_gerenciador_de_configuracao,
}


class AjusteDoAnsible(importlib.abc.MetaPathFinder):
    def find_spec(self, nome, caminho, alvo=None):
        if nome not in AJUSTES or getattr(self, 'carregando', None) == nome:
            return None
        self.carregando = nome
        try:
            especificacao = importlib.util.find_spec(nome)
        finally:
            self.carregando = None
        executar_modulo = especificacao.loader.exec_module

        def executar_e_ajustar(modulo):
            executar_modulo(modulo)
            AJUSTES[nome](modulo)

        especificacao.loader.exec_module = executar_e_ajustar
        return especificacao


os.path.expanduser = expanduser
sys.meta_path.insert(0, AjusteDoAnsible())
'@

    return $script
}
