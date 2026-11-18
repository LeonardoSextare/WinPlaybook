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
    //servidor/infra), que continuam válidos num JSON. Nos comandos que falam do nó de
    controle (ansible-config, ansible-doc, ansible-galaxy e ansible --version), os caminhos
    do disco da distribuição também mudam: o que leva a uma pasta do Windows, como as
    collections do perfil, vira o caminho dela no Windows, e o resto vira
    //wsl.localhost/<distribuição>/.... Nos outros comandos, esses caminhos podem ser dos
    hosts e ficam como estão. Um script com shebang e finais de
    linha CRLF, como os que o Git for Windows grava, vai sem os CR pelo ansible.builtin.script,
    e o arquivo do projeto não muda. Um arquivo .bat, .cmd, .exe, .com, .ps1, .py ou .sh da
    raiz de montagem, que não tem a permissão de execução, conta como executável para o
    Ansible, como um script de senha do vault ou de inventário, e roda pela extensão: o .bat
    e o .cmd pelo cmd.exe, o .exe e o .com pela montagem com execução, o .ps1 pelo
    powershell.exe, e o .py e o .sh pelo shebang, ou pelo Python do Ansible e pelo /bin/sh,
    com os finais de linha CRLF do .sh convertidos. A raiz de montagem vem da variável
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
import json
import os
import re
import shutil
import stat
import subprocess
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
programa_eh_do_ansible = []


def mostrar_caminho_do_windows(ocorrencia):
    if ocorrencia.group('servidor'):
        return b'//' + ocorrencia.group('servidor') + b'/' + ocorrencia.group('compartilhamento')
    return ocorrencia.group('unidade').upper() + b':'


def traduzir_saida(dados):
    raiz = re.escape(os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/').encode())
    padrao = rb'(?<![\w/.-])' + raiz + rb'/(?:unc/(?P<servidor>[^/\s\'"]+)/(?P<compartilhamento>[^/\s\'"]+)|(?P<unidade>[a-z])(?![\w.-]))'
    return re.sub(padrao, mostrar_caminho_do_windows, dados)


CAMINHO_DA_DISTRIBUICAO = re.compile(rb'(?<![\w/.~-])/(?:home|root|tmp|usr|etc|opt|var|srv)(?:/[^\s\'"\],:;=()]*)?')
PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES = b'/opt/winplaybook/exec/'
PROGRAMAS_DO_NO_DE_CONTROLE = ('ansible-config', 'ansible-doc', 'ansible-galaxy')
programa_mostra_caminhos_da_distribuicao = []


def mostra_caminhos_da_distribuicao():
    if not programa_mostra_caminhos_da_distribuicao:
        argumentos = getattr(sys, 'argv', ['']) or ['']
        programa = os.path.basename(argumentos[0] or '')
        mostra = programa in PROGRAMAS_DO_NO_DE_CONTROLE or (programa == 'ansible' and '--version' in argumentos[1:])
        programa_mostra_caminhos_da_distribuicao.append(mostra)
    return programa_mostra_caminhos_da_distribuicao[0]


def mostrar_caminho_da_distribuicao(ocorrencia):
    caminho = ocorrencia.group(0)
    real = os.path.realpath(caminho)
    raiz = os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/').encode() + b'/'
    if real.startswith(PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES):
        real = raiz + real[len(PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES):]
    if real.startswith(raiz):
        return traduzir_saida(real)
    distribuicao = os.environ.get('WSL_DISTRO_NAME')
    return b'//wsl.localhost/' + distribuicao.encode() + caminho if distribuicao else caminho


def eh_programa_do_ansible():
    if not programa_eh_do_ansible:
        programa = os.path.basename(getattr(sys, 'argv', [''])[0] or '')
        programa_eh_do_ansible.append(bool(PROGRAMA_DO_ANSIBLE.match(programa)))
    return programa_eh_do_ansible[0]


class SaidaComCaminhosDoWindows(io.BufferedIOBase):
    def __init__(self, original):
        self._original = original

    def write(self, dados):
        tamanho = len(dados)
        if eh_programa_do_ansible():
            dados = traduzir_saida(bytes(dados))
        if mostra_caminhos_da_distribuicao():
            dados = CAMINHO_DA_DISTRIBUICAO.sub(mostrar_caminho_da_distribuicao, bytes(dados))
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


EXTENSOES_DE_SCRIPT = ('.bat', '.cmd', '.exe', '.com', '.ps1', '.py', '.sh')
EXECUTAR_WINDOWS = '/usr/local/lib/winplaybook/executar-windows'
PASTA_DA_MONTAGEM_COM_EXECUCAO = '/opt/winplaybook/exec/'
access_original = os.access
popen_original = subprocess.Popen


def ler_shebang(caminho):
    try:
        with open(caminho, 'rb') as arquivo:
            primeira_linha = arquivo.readline(4096)
    except OSError:
        return None
    if not primeira_linha.startswith(b'#!'):
        return None
    return os.fsdecode(primeira_linha[2:]).strip().split(None, 1) or None


def caminho_do_script_do_windows(caminho):
    if not isinstance(caminho, (str, bytes)):
        return None
    caminho = os.path.abspath(os.fsdecode(caminho))
    raiz = os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/') + '/'
    if not caminho.startswith(raiz) or os.path.splitext(caminho)[1].lower() not in EXTENSOES_DE_SCRIPT:
        return None
    try:
        modo = os.stat(caminho).st_mode
    except (OSError, ValueError):
        return None
    if not stat.S_ISREG(modo) or modo & 0o111:
        return None
    return caminho


def comando_do_script_do_windows(caminho):
    caminho = caminho_do_script_do_windows(caminho)
    if caminho is None:
        return None
    extensao = os.path.splitext(caminho)[1].lower()
    if extensao in ('.bat', '.cmd'):
        return [EXECUTAR_WINDOWS, caminho]
    if extensao in ('.exe', '.com'):
        relativo = caminho[len(os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/') + '/'):]
        caminho_com_execucao = PASTA_DA_MONTAGEM_COM_EXECUCAO + relativo
        tem_montagem_com_execucao = re.match(r'^[a-z]/', relativo) and os.path.isfile(caminho_com_execucao)
        return [EXECUTAR_WINDOWS, caminho_com_execucao] if tem_montagem_com_execucao else None
    if extensao == '.ps1':
        powershell = shutil.which('powershell.exe')
        return [powershell, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', caminho] if powershell else None
    if extensao == '.py':
        return (ler_shebang(caminho) or [sys.executable]) + [caminho]
    try:
        with open(caminho, 'rb') as arquivo:
            conteudo = os.fsdecode(arquivo.read().replace(b'\r\n', b'\n'))
    except OSError:
        return None
    return (ler_shebang(caminho) or ['/bin/sh']) + ['-c', conteudo, caminho]


def access_com_scripts_do_windows(caminho, modo, *args, **kwargs):
    if modo & os.X_OK and eh_programa_do_ansible() and caminho_do_script_do_windows(caminho):
        return access_original(caminho, modo & ~os.X_OK, *args, **kwargs)
    return access_original(caminho, modo, *args, **kwargs)


class PopenComScriptsDoWindows(popen_original):
    def __init__(self, args, *outros, **opcoes):
        if isinstance(args, (list, tuple)) and args and not opcoes.get('shell') and eh_programa_do_ansible():
            comando = comando_do_script_do_windows(args[0])
            if comando:
                args = comando + list(args[1:])
        super().__init__(args, *outros, **opcoes)


def ajustar_arquivo(modulo):
    is_executable = modulo.is_executable

    def is_executable_com_scripts_do_windows(caminho):
        return is_executable(caminho) or (eh_programa_do_ansible() and caminho_do_script_do_windows(caminho) is not None)

    modulo.is_executable = is_executable_com_scripts_do_windows


HOST_DA_MAQUINA_WINDOWS = 'localhost_windows'


def criar_host_da_maquina_windows():
    try:
        configuracao = json.loads(os.environ.get('WINPLAYBOOK_LOCALHOST_WINDOWS', ''))
    except ValueError:
        return None
    from ansible.inventory.host import Host
    host = Host(HOST_DA_MAQUINA_WINDOWS)
    host.address = '127.0.0.1'
    host.implicit = True
    variaveis = {
        'ansible_host': '127.0.0.1',
        'ansible_port': configuracao['porta'],
        'ansible_user': configuracao['usuario'],
        'ansible_connection': 'ssh',
        'ansible_shell_type': 'cmd',
        'ansible_ssh_private_key_file': configuracao['chave'],
        'ansible_ssh_common_args': '-o UserKnownHostsFile=' + configuracao['knownHosts'] + ' -o StrictHostKeyChecking=accept-new',
    }
    for nome, valor in variaveis.items():
        host.set_variable(nome, valor)
    return host


def ajustar_dados_do_inventario(modulo):
    get_host = modulo.InventoryData.get_host

    def get_host_com_a_maquina_windows(self, hostname):
        host = get_host(self, hostname)
        if host is None and hostname == HOST_DA_MAQUINA_WINDOWS:
            if not hasattr(self, '_host_da_maquina_windows'):
                self._host_da_maquina_windows = criar_host_da_maquina_windows()
            host = self._host_da_maquina_windows
        return host

    modulo.InventoryData.get_host = get_host_com_a_maquina_windows


def ajustar_gerenciador_de_inventario(modulo):
    enumerate_matches = modulo.InventoryManager._enumerate_matches

    def enumerate_matches_com_a_maquina_windows(self, pattern):
        if pattern == HOST_DA_MAQUINA_WINDOWS and pattern not in self._inventory.hosts:
            host = self._inventory.get_host(pattern)
            if host is not None:
                return [host]
        return enumerate_matches(self, pattern)

    modulo.InventoryManager._enumerate_matches = enumerate_matches_com_a_maquina_windows


AJUSTES = {
    'ansible.parsing.dataloader': lambda modulo: ajustar_data_loader(modulo.DataLoader),
    'ansible.config.manager': ajustar_gerenciador_de_configuracao,
    'ansible.utils.shlex': ajustar_shlex,
    'ansible.plugins.action': ajustar_action_base,
    'ansible.module_utils.common.file': ajustar_arquivo,
    'ansible.inventory.data': ajustar_dados_do_inventario,
    'ansible.inventory.manager': ajustar_gerenciador_de_inventario,
}


class CarregadorAjustado(importlib.abc.Loader):
    def __init__(self, original, nome):
        self._original = original
        self._nome = nome

    def create_module(self, especificacao):
        return self._original.create_module(especificacao)

    def exec_module(self, modulo):
        self._original.exec_module(modulo)
        AJUSTES[self._nome](modulo)

    def __getattr__(self, nome):
        return getattr(self._original, nome)


class AjusteDoAnsible(importlib.abc.MetaPathFinder):
    def find_spec(self, nome, caminho, alvo=None):
        if nome not in AJUSTES or getattr(self, 'carregando', None) == nome:
            return None
        self.carregando = nome
        try:
            especificacao = importlib.util.find_spec(nome)
        finally:
            self.carregando = None
        especificacao.loader = CarregadorAjustado(especificacao.loader, nome)
        return especificacao


os.path.expanduser = expanduser
os.access = access_com_scripts_do_windows
subprocess.Popen = PopenComScriptsDoWindows
sys.meta_path.insert(0, AjusteDoAnsible())
sys.stdout = mostrar_saida_com_caminhos_do_windows(sys.stdout)
sys.stderr = mostrar_saida_com_caminhos_do_windows(sys.stderr)
'@

    return $script
}
