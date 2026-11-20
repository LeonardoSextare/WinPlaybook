import atexit
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile

from .comum import eh_programa_do_ansible, raiz_de_montagem

EXTENSOES_DE_SCRIPT = ('.bat', '.cmd', '.exe', '.com', '.ps1', '.py', '.sh')
EXECUTAR_WINDOWS = '/usr/local/lib/winplaybook/executar-windows'
PASTA_DA_MONTAGEM_COM_EXECUCAO = '/opt/winplaybook/exec/'
ACOES_DE_COPIA = ('copy', 'ansible.builtin.copy', 'ansible.legacy.copy')
FAMILIAS_DE_SHELL_DO_WINDOWS = ('powershell', 'cmd')
pasta_das_copias_sem_crlf = []
access_original = os.access
popen_original = subprocess.Popen


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

def copia_do_script_sem_crlf(caminho_local):
    try:
        with open(caminho_local, 'rb') as arquivo:
            conteudo = arquivo.read()
    except OSError:
        return caminho_local
    if not conteudo.startswith(b'#!') or b'\r\n' not in conteudo:
        return caminho_local
    if not pasta_das_copias_sem_crlf:
        pasta_das_copias_sem_crlf.append(tempfile.mkdtemp(prefix='winplaybook-copy-'))
        atexit.register(shutil.rmtree, pasta_das_copias_sem_crlf[0], True)
    pasta = tempfile.mkdtemp(dir=pasta_das_copias_sem_crlf[0])
    copia = os.path.join(pasta, os.path.basename(caminho_local))
    with open(copia, 'wb') as arquivo:
        arquivo.write(conteudo.replace(b'\r\n', b'\n'))
    shutil.copymode(caminho_local, copia)
    return copia


def host_eh_windows(acao):
    shell = getattr(getattr(acao, '_connection', None), '_shell', None)
    return getattr(shell, 'SHELL_FAMILY', '') in FAMILIAS_DE_SHELL_DO_WINDOWS


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

    find_needle = modulo.ActionBase._find_needle

    def find_needle_sem_crlf(self, dirname, needle):
        caminho = find_needle(self, dirname, needle)
        acao = getattr(getattr(self, '_task', None), 'action', '')
        if acao in ACOES_DE_COPIA and os.path.isfile(caminho) and not host_eh_windows(self):
            return copia_do_script_sem_crlf(caminho)
        return caminho

    modulo.ActionBase._find_needle = find_needle_sem_crlf


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
    raiz = raiz_de_montagem() + '/'
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
        relativo = caminho[len(raiz_de_montagem() + '/'):]
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


AJUSTES = {
    'ansible.plugins.action': ajustar_action_base,
    'ansible.module_utils.common.file': ajustar_arquivo,
}


def instalar():
    os.access = access_com_scripts_do_windows
    subprocess.Popen = PopenComScriptsDoWindows
