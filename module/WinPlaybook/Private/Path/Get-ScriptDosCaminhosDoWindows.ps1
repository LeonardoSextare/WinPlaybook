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
    roles_path, pode separar caminhos do Windows por ponto e vírgula, e um inventário INI
    mantém as barras invertidas de um caminho do Windows sem aspas. No caminho de volta, o
    que os comandos do Ansible, como o ansible-playbook e o ansible-lint, escrevem na saída
    troca os caminhos da raiz de montagem pelos do Windows, com barras normais (/mnt/c/infra vira C:/infra, e /mnt/unc/servidor/infra vira
    //servidor/infra), que continuam válidos num JSON. Um script com shebang e finais de
    linha CRLF, como os que o Git for Windows grava, vai sem os CR pelo ansible.builtin.script,
    e o arquivo do projeto não muda. A raiz de montagem vem da variável
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
import io
import os
import re
import sys
import tempfile

CAMINHO_DO_WINDOWS = re.compile(r'^[A-Za-z]:[\\/]')
CAMINHO_DO_WINDOWS_EM_BYTES = re.compile(rb'^[A-Za-z]:[\\/]')
LISTA_COM_CAMINHO_DO_WINDOWS = re.compile(r'(^|;)\s*[A-Za-z]:[\\/]')
CAMINHO_DO_WINDOWS_SEM_ASPAS = re.compile(r'((?:^|(?<=[\s=]))[A-Za-z]:)(\\[^\s\'"]*)')
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


def proteger_barras(ocorrencia):
    return ocorrencia.group(1) + ocorrencia.group(2).replace('\\', '\\\\')


def ajustar_shlex(modulo):
    shlex_split = modulo.shlex_split

    def shlex_split_com_windows(texto, *args, **kwargs):
        return shlex_split(CAMINHO_DO_WINDOWS_SEM_ASPAS.sub(proteger_barras, texto), *args, **kwargs)

    modulo.shlex_split = shlex_split_com_windows


PROGRAMA_DO_ANSIBLE = re.compile(r'^ansible(-[a-z]+)?$')
programa_mostra_caminhos_do_windows = []


def mostrar_caminho_do_windows(ocorrencia):
    if ocorrencia.group('servidor'):
        return b'//' + ocorrencia.group('servidor') + b'/' + ocorrencia.group('compartilhamento')
    return ocorrencia.group('unidade').upper() + b':'


def traduzir_saida(dados):
    raiz = re.escape(os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/').encode())
    padrao = rb'(?<![\w/.-])' + raiz + rb'/(?:unc/(?P<servidor>[^/\s\'"]+)/(?P<compartilhamento>[^/\s\'"]+)|(?P<unidade>[a-z])(?![\w.-]))'
    return re.sub(padrao, mostrar_caminho_do_windows, dados)


def mostra_caminhos_do_windows():
    if not programa_mostra_caminhos_do_windows:
        programa = os.path.basename(getattr(sys, 'argv', [''])[0] or '')
        programa_mostra_caminhos_do_windows.append(bool(PROGRAMA_DO_ANSIBLE.match(programa)))
    return programa_mostra_caminhos_do_windows[0]


class SaidaComCaminhosDoWindows(io.BufferedIOBase):
    def __init__(self, original):
        self._original = original

    def write(self, dados):
        tamanho = len(dados)
        if mostra_caminhos_do_windows():
            dados = traduzir_saida(bytes(dados))
        self._original.write(dados)
        return tamanho

    def flush(self):
        return self._original.flush()

    def fileno(self):
        return self._original.fileno()

    def isatty(self):
        return self._original.isatty()

    def writable(self):
        return True

    def readable(self):
        return False

    @property
    def closed(self):
        return self._original.closed

    def __getattr__(self, nome):
        return getattr(self._original, nome)


def mostrar_saida_com_caminhos_do_windows(saida):
    if saida is None or not hasattr(saida, 'buffer'):
        return saida
    return io.TextIOWrapper(SaidaComCaminhosDoWindows(saida.buffer), encoding=saida.encoding, errors=saida.errors, line_buffering=saida.line_buffering, write_through=True)


def converter_script_com_crlf(caminho_local):
    try:
        with open(caminho_local, 'rb') as arquivo:
            conteudo = arquivo.read()
    except OSError:
        return caminho_local
    if not conteudo.startswith(b'#!') or b'\r\n' not in conteudo:
        return caminho_local
    descritor, caminho_convertido = tempfile.mkstemp(prefix='winplaybook-script-')
    with os.fdopen(descritor, 'wb') as arquivo:
        arquivo.write(conteudo.replace(b'\r\n', b'\n'))
    return caminho_convertido


def ajustar_action_base(modulo):
    transfer_file = modulo.ActionBase._transfer_file

    def transfer_file_sem_crlf(self, local_path, remote_path):
        acao = getattr(getattr(self, '_task', None), 'action', '')
        if acao not in ('script', 'ansible.builtin.script', 'ansible.legacy.script'):
            return transfer_file(self, local_path, remote_path)
        caminho_enviado = converter_script_com_crlf(local_path)
        try:
            return transfer_file(self, caminho_enviado, remote_path)
        finally:
            if caminho_enviado != local_path:
                os.remove(caminho_enviado)

    modulo.ActionBase._transfer_file = transfer_file_sem_crlf


AJUSTES = {
    'ansible.parsing.dataloader': lambda modulo: ajustar_data_loader(modulo.DataLoader),
    'ansible.config.manager': ajustar_gerenciador_de_configuracao,
    'ansible.utils.shlex': ajustar_shlex,
    'ansible.plugins.action': ajustar_action_base,
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
sys.stdout = mostrar_saida_com_caminhos_do_windows(sys.stdout)
sys.stderr = mostrar_saida_com_caminhos_do_windows(sys.stderr)
'@

    return $script
}
