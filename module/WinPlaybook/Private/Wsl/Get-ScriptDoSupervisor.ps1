function Get-ScriptDoSupervisor {
    <#
    .SYNOPSIS
    Devolve o script Python que executa o comando na distribuição e o encerra junto com o Windows.

    .DESCRIPTION
    O script recebe nos argumentos o comando e os argumentos dele, e na variável
    WINPLAYBOOK_ENVIRONMENT um JSON com as variáveis de ambiente do
    comando (variaveis) e as pastas do Path do Windows na montagem com execução
    (pathDoWindows). Ele executa o comando
    com essas variáveis somadas às da distribuição e sai com o código de
    saída dele, ou com 128 mais o número do sinal que o encerrou. Os processos que o comando
    deixa para trás, mesmo numa sessão própria, como os workers do Ansible, ficam sob o
    script.

    Os programas .com, .exe, .bat e .cmd das pastas do Path do Windows entram no fim do PATH,
    pela pasta ~/.cache/winplaybook/path-do-windows, com o nome completo e com o nome sem a
    extensão, na ordem do Path e do PATHEXT, como no Windows. O nome sem a extensão fica de
    fora para o Python e o pip, que a detecção de interpretador do Ansible procuraria. A pasta
    é gerada de novo só quando as pastas do Path mudam.

    Quando o ~/.ssh/config, que é o config do ssh do Windows, tem caminhos do Windows, o
    script grava uma cópia traduzida em ~/.cache/winplaybook/ssh_config, que o
    /usr/local/bin/ssh usa. Um caminho da pasta .ssh do Windows vira ~/.ssh, os outros viram
    os da raiz de montagem, o IdentityAgent do pipe do agente do Windows vira o
    SSH_AUTH_SOCK, e um ProxyCommand com o ssh.exe do Windows passa a usar o ssh da
    distribuição. Sem caminhos do Windows, a cópia não existe.

    O git da distribuição usa o .gitconfig do perfil do Windows, por uma cópia traduzida em
    ~/.cache/winplaybook/gitconfig que o GIT_CONFIG_GLOBAL aponta: o credential.helper do
    Git for Windows (manager) vira o Git Credential Manager do Windows, pela montagem com
    execução, o core.sshCommand com o ssh.exe vira o ssh da distribuição, e os outros
    caminhos do Windows viram os da raiz de montagem. Sem .gitconfig, a cópia só liga o Git
    Credential Manager, quando o Git for Windows está no Path.

    Sem o EDITOR e o VISUAL no Windows, o EDITOR do ansible-vault é o notepad.exe, que o
    ansible-vault create e edit abrem pelo Path do Windows. O notepad.exe espera a janela
    fechar, como o ansible-vault precisa.

    Quando a entrada padrão não é um terminal, ela chega ao comando por um pipe do próprio
    usuário, e o comando pode reabri-la pelo /dev/stdin. O pipe que o WSL entrega é do root.

    Quando o processo do Windows que chamou o WSL termina, o script recebe SIGHUP, ou SIGTERM,
    e encerra o comando e todos esses processos. Um Ctrl+C chega ao comando, que decide o que
    fazer, e o script continua esperando por ele.

    .EXAMPLE
    $script = Get-ScriptDoSupervisor

    Devolve o código Python, para o python3 da distribuição executar com o comando nos
    argumentos.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $script = @'
import base64
import ctypes
import glob
import hashlib
import json
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time

PR_SET_CHILD_SUBREAPER = 36
PASTA_DO_PATH_DO_WINDOWS = os.path.expanduser('~/.cache/winplaybook/path-do-windows')
EXECUTAR_WINDOWS = '/usr/local/lib/winplaybook/executar-windows'
PRIORIDADE_DAS_EXTENSOES = {'.com': 0, '.exe': 1, '.bat': 2, '.cmd': 3}
NOME_CURTO_RESERVADO = re.compile(r'^(python|pip|py)[0-9.]*$', re.IGNORECASE)
CAMINHO_DO_WINDOWS = re.compile(r'^[A-Za-z]:[\\/]')
LINHA_DO_SSH = re.compile(r'^(\s*)(IdentityFile|CertificateFile|UserKnownHostsFile|GlobalKnownHostsFile|IdentityAgent|ControlPath|Include|RevokedHostKeys|ProxyCommand)(\s*=\s*|\s+)(.*?)\s*$', re.IGNORECASE)
PROGRAMA_DO_PROXY = re.compile(r'^("[^"]+"|\S+)')
LINHA_DO_GIT = re.compile(r'^(\s*)([A-Za-z][\w-]*)(\s*=\s*)(.*?)\s*$')
CAMINHO_DO_WINDOWS_NO_GIT = re.compile(r'^"?[A-Za-z]:(\\\\|\\|/)')
HELPER_DO_WINDOWS = re.compile(r'^"?(manager(-core)?|.*git-credential-manager(\.exe)?)"?$', re.IGNORECASE)
sinais_de_fim = []


def guardar_sinal_de_fim(numero, quadro):
    sinais_de_fim.append(numero)


def ignorar_interrupcao(numero, quadro):
    pass


def listar_descendentes():
    filhos_por_pai = {}
    for nome in os.listdir('/proc'):
        if not nome.isdigit():
            continue
        try:
            with open('/proc/' + nome + '/stat') as arquivo:
                pid_do_pai = int(arquivo.read().rsplit(')', 1)[1].split()[1])
        except (OSError, IndexError, ValueError):
            continue
        filhos_por_pai.setdefault(pid_do_pai, []).append(int(nome))
    descendentes = []
    pendentes = [os.getpid()]
    while pendentes:
        for pid in filhos_por_pai.get(pendentes.pop(), []):
            descendentes.append(pid)
            pendentes.append(pid)
    return descendentes


def recolher_terminados():
    while True:
        try:
            pid, _ = os.waitpid(-1, os.WNOHANG)
        except ChildProcessError:
            return
        if pid == 0:
            return


def encerrar_descendentes():
    for sinal in (signal.SIGTERM, signal.SIGKILL):
        for pid in listar_descendentes():
            try:
                os.kill(pid, sinal)
            except ProcessLookupError:
                pass
        prazo = time.monotonic() + 3
        while time.monotonic() < prazo:
            recolher_terminados()
            if not listar_descendentes():
                return
            time.sleep(0.1)


def repassar_entrada(destino):
    try:
        while True:
            bloco = os.read(0, 65536)
            if not bloco:
                return
            while bloco:
                bloco = bloco[os.write(destino, bloco):]
    except OSError:
        pass
    finally:
        os.close(destino)


def criar_entrada_do_usuario():
    if os.isatty(0):
        return None
    leitura, escrita = os.pipe()
    threading.Thread(target=repassar_entrada, args=(escrita,), daemon=True).start()
    return leitura


def calcular_impressao(pastas):
    estado = []
    for pasta in pastas:
        try:
            estado.append(pasta + '\t' + str(os.stat(pasta).st_mtime_ns))
        except OSError:
            estado.append(pasta + '\t-')
    return hashlib.sha256('\n'.join(estado).encode('utf-8')).hexdigest()


def criar_entrada_de_programa(pasta_nova, nome_no_path, caminho_do_programa):
    with open(os.path.join(pasta_nova, nome_no_path), 'w') as arquivo:
        arquivo.write('#!/bin/sh\nexec ' + EXECUTAR_WINDOWS + ' ' + shlex.quote(caminho_do_programa) + ' "$@"\n')
    os.chmod(os.path.join(pasta_nova, nome_no_path), 0o755)


def gerar_path_do_windows(pastas, pasta_nova):
    criados = set()
    for pasta in pastas:
        try:
            nomes = os.listdir(pasta)
        except OSError:
            continue
        programas = sorted((PRIORIDADE_DAS_EXTENSOES[os.path.splitext(nome)[1].lower()], nome) for nome in nomes if os.path.splitext(nome)[1].lower() in PRIORIDADE_DAS_EXTENSOES)
        for _, nome in programas:
            base, extensao = os.path.splitext(nome)
            nomes_no_path = [nome]
            if not NOME_CURTO_RESERVADO.match(base):
                nomes_no_path += [base, base.lower()]
            for nome_no_path in nomes_no_path:
                if nome_no_path not in criados:
                    criados.add(nome_no_path)
                    criar_entrada_de_programa(pasta_nova, nome_no_path, pasta + '/' + nome)


def preparar_path_do_windows(pastas):
    impressao = calcular_impressao(pastas)
    try:
        with open(os.path.join(PASTA_DO_PATH_DO_WINDOWS, '.impressao')) as arquivo:
            if arquivo.read() == impressao:
                return PASTA_DO_PATH_DO_WINDOWS
    except OSError:
        pass
    pasta_do_cache = os.path.dirname(PASTA_DO_PATH_DO_WINDOWS)
    os.makedirs(pasta_do_cache, exist_ok=True)
    pasta_nova = tempfile.mkdtemp(prefix='path-do-windows.', dir=pasta_do_cache)
    gerar_path_do_windows(pastas, pasta_nova)
    with open(os.path.join(pasta_nova, '.impressao'), 'w') as arquivo:
        arquivo.write(impressao)
    atalho_novo = pasta_nova + '.atalho'
    os.symlink(os.path.basename(pasta_nova), atalho_novo)
    os.replace(atalho_novo, PASTA_DO_PATH_DO_WINDOWS)
    for nome in os.listdir(pasta_do_cache):
        caminho = os.path.join(pasta_do_cache, nome)
        if nome.startswith('path-do-windows.') and caminho != pasta_nova and os.path.isdir(caminho) and not os.path.islink(caminho):
            shutil.rmtree(caminho, ignore_errors=True)
    return PASTA_DO_PATH_DO_WINDOWS


def ler_pasta_do_ssh_no_windows():
    pasta_do_ssh = os.path.expanduser('~/.ssh')
    try:
        with open('/proc/mounts') as arquivo:
            for linha in arquivo:
                campos = linha.split()
                if len(campos) > 3 and campos[1] == pasta_do_ssh:
                    opcoes = re.sub(r'\\([0-7]{3})', lambda octal: chr(int(octal.group(1), 8)), campos[3])
                    for opcao in opcoes.split(';'):
                        if opcao.startswith('path='):
                            return opcao[len('path='):].rstrip('\\')
    except OSError:
        pass
    return None


def converter_caminho_do_ssh(caminho, pasta_do_ssh_no_windows):
    texto = caminho.strip('"')
    if not CAMINHO_DO_WINDOWS.match(texto):
        return caminho
    normalizado = texto.replace('/', '\\')
    if pasta_do_ssh_no_windows and normalizado.lower().startswith(pasta_do_ssh_no_windows.lower() + '\\'):
        convertido = '~/.ssh/' + normalizado[len(pasta_do_ssh_no_windows) + 1:].replace('\\', '/')
    else:
        raiz = os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/')
        convertido = raiz + '/' + normalizado[0].lower() + normalizado[2:].replace('\\', '/')
    return '"' + convertido + '"' if ' ' in convertido else convertido


def converter_linha_do_ssh(linha, pasta_do_ssh_no_windows):
    ocorrencia = LINHA_DO_SSH.match(linha)
    if not ocorrencia:
        return linha
    inicio, opcao, separador, valor = ocorrencia.groups()
    opcao_em_minusculas = opcao.lower()
    if opcao_em_minusculas == 'identityagent' and valor.strip('"').lower().startswith('\\\\.\\pipe\\'):
        return inicio + opcao + separador + 'SSH_AUTH_SOCK'
    if opcao_em_minusculas == 'proxycommand':
        programa = PROGRAMA_DO_PROXY.match(valor)
        if not programa or not CAMINHO_DO_WINDOWS.match(programa.group(1).strip('"')):
            return linha
        caminho_do_programa = programa.group(1).strip('"')
        resto = valor[programa.end(1):]
        if caminho_do_programa.replace('/', '\\').lower().endswith('\\ssh.exe'):
            return inicio + opcao + separador + 'ssh' + resto
        convertido = '/opt/winplaybook/exec/' + caminho_do_programa[0].lower() + caminho_do_programa[2:].replace('\\', '/')
        return inicio + opcao + separador + shlex.quote(convertido) + resto
    caminhos = re.findall(r'"[^"]*"|\S+', valor)
    return inicio + opcao + separador + ' '.join(converter_caminho_do_ssh(caminho, pasta_do_ssh_no_windows) for caminho in caminhos)


def achar_gerenciador_de_credenciais(pastas_do_path):
    for pasta in pastas_do_path:
        if os.path.isfile(pasta + '/git.exe'):
            for raiz_do_git in (os.path.dirname(pasta), os.path.dirname(os.path.dirname(pasta))):
                for relativo in ('/*/bin/git-credential-manager.exe', '/*/libexec/git-core/git-credential-manager.exe'):
                    encontrados = sorted(glob.glob(glob.escape(raiz_do_git) + relativo))
                    if encontrados:
                        return encontrados[0]
    return None


def converter_valor_do_git(chave, valor, gerenciador_de_credenciais):
    if chave == 'helper' and HELPER_DO_WINDOWS.match(valor):
        return '"\'' + gerenciador_de_credenciais + '\'"' if gerenciador_de_credenciais else None
    if not CAMINHO_DO_WINDOWS_NO_GIT.match(valor):
        return valor
    caminho = valor.strip('"').replace('\\\\', '\\').replace('\\', '/')
    if chave == 'sshcommand' and caminho.lower().split(' ')[0].endswith('/ssh.exe'):
        return 'ssh' + caminho[caminho.lower().index('/ssh.exe') + len('/ssh.exe'):]
    raiz = os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/')
    return '"' + raiz + '/' + caminho[0].lower() + caminho[2:] + '"'


def preparar_config_do_git(pastas_do_path):
    perfil = os.environ.get('USERPROFILE', '')
    origem = os.path.join(perfil, '.gitconfig') if perfil else None
    gerenciador_de_credenciais = achar_gerenciador_de_credenciais(pastas_do_path)
    try:
        with open(origem, encoding='utf-8-sig', errors='surrogateescape') as arquivo:
            original = arquivo.read().splitlines()
    except (OSError, TypeError):
        original = []
    if not original and not gerenciador_de_credenciais:
        return
    traduzido = []
    tem_helper = False
    for linha in original:
        ocorrencia = LINHA_DO_GIT.match(linha)
        if not ocorrencia or linha.lstrip().startswith(('#', ';', '[')):
            traduzido.append(linha)
            continue
        inicio, chave, separador, valor = ocorrencia.groups()
        tem_helper = tem_helper or chave.lower() == 'helper'
        convertido = converter_valor_do_git(chave.lower(), valor, gerenciador_de_credenciais)
        if convertido is not None:
            traduzido.append(inicio + chave + separador + convertido)
    if gerenciador_de_credenciais and not tem_helper:
        traduzido += ['[credential]', '\thelper = "\'' + gerenciador_de_credenciais + '\'"']
    destino = os.path.expanduser('~/.cache/winplaybook/gitconfig')
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    temporario = destino + '.' + str(os.getpid())
    with open(temporario, 'w', encoding='utf-8', errors='surrogateescape') as arquivo:
        arquivo.write('\n'.join(traduzido) + '\n')
    os.replace(temporario, destino)
    os.environ['GIT_CONFIG_GLOBAL'] = destino


def preparar_config_do_ssh():
    destino = os.path.expanduser('~/.cache/winplaybook/ssh_config')
    try:
        with open(os.path.expanduser('~/.ssh/config'), encoding='utf-8-sig', errors='surrogateescape') as arquivo:
            original = arquivo.read().splitlines()
    except OSError:
        original = None
    if original is not None:
        pasta_do_ssh_no_windows = ler_pasta_do_ssh_no_windows()
        traduzido = [converter_linha_do_ssh(linha, pasta_do_ssh_no_windows) for linha in original]
        if traduzido != original:
            os.makedirs(os.path.dirname(destino), exist_ok=True)
            temporario = destino + '.' + str(os.getpid())
            descritor = os.open(temporario, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(descritor, 'w', encoding='utf-8', errors='surrogateescape') as arquivo:
                arquivo.write('\n'.join(traduzido) + '\n\nMatch all\nInclude /etc/ssh/ssh_config\n')
            os.replace(temporario, destino)
            return
    try:
        os.remove(destino)
    except OSError:
        pass


ctypes.CDLL(None).prctl(PR_SET_CHILD_SUBREAPER, 1, 0, 0, 0)
signal.signal(signal.SIGHUP, guardar_sinal_de_fim)
signal.signal(signal.SIGTERM, guardar_sinal_de_fim)
signal.signal(signal.SIGINT, ignorar_interrupcao)

entrada = criar_entrada_do_usuario()
ambiente = json.loads(os.environ.pop('WINPLAYBOOK_ENVIRONMENT'))
os.environ.update(ambiente['variaveis'])
os.environ['PATH'] = os.environ.get('PATH', '') + ':' + preparar_path_do_windows(ambiente['pathDoWindows'])
preparar_config_do_ssh()
preparar_config_do_git(ambiente['pathDoWindows'])
if os.path.basename(sys.argv[1]) == 'ansible-vault' and not os.environ.get('EDITOR') and not os.environ.get('VISUAL'):
    os.environ['EDITOR'] = 'notepad.exe'
comando = subprocess.Popen(sys.argv[1:], stdin=entrada)
if entrada is not None:
    os.close(entrada)
while comando.poll() is None and not sinais_de_fim:
    try:
        comando.wait(timeout=0.2)
    except subprocess.TimeoutExpired:
        pass

if sinais_de_fim:
    encerrar_descendentes()
    sys.exit(128 + sinais_de_fim[0])

codigo_de_saida = comando.returncode
if codigo_de_saida < 0:
    codigo_de_saida = 128 - codigo_de_saida
sys.exit(codigo_de_saida)
'@

    return $script
}
