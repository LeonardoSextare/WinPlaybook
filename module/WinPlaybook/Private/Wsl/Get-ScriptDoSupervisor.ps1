function Get-ScriptDoSupervisor {
    <#
    .SYNOPSIS
    Devolve o script Python que executa o comando na distribuição e o encerra junto com o Windows.

    .DESCRIPTION
    O script recebe, depois do próprio código, um JSON codificado em Base64, com as variáveis
    de ambiente do comando (variaveis) e as pastas do Path do Windows na montagem com
    execução (pathDoWindows), e então o comando e os argumentos dele. Ele executa o comando
    com essas variáveis somadas às da distribuição e sai com o código de
    saída dele, ou com 128 mais o número do sinal que o encerrou. Os processos que o comando
    deixa para trás, mesmo numa sessão própria, como os workers do Ansible, ficam sob o
    script.

    Os programas .com, .exe, .bat e .cmd das pastas do Path do Windows entram no fim do PATH,
    pela pasta ~/.cache/winplaybook/path-do-windows, com o nome completo e com o nome sem a
    extensão, na ordem do Path e do PATHEXT, como no Windows. O nome sem a extensão fica de
    fora para o Python e o pip, que a detecção de interpretador do Ansible procuraria. A pasta
    é gerada de novo só quando as pastas do Path mudam.

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
EXECUTAR_BAT = '/usr/local/lib/winplaybook/executar-bat'
PRIORIDADE_DAS_EXTENSOES = {'.com': 0, '.exe': 1, '.bat': 2, '.cmd': 3}
NOME_CURTO_RESERVADO = re.compile(r'^(python|pip|py)[0-9.]*$', re.IGNORECASE)
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


def criar_entrada_de_programa(pasta_nova, nome_no_path, caminho_do_programa, extensao):
    destino = os.path.join(pasta_nova, nome_no_path)
    if extensao in ('.com', '.exe'):
        os.symlink(caminho_do_programa, destino)
        return
    with open(destino, 'w') as arquivo:
        arquivo.write('#!/bin/sh\nexec ' + EXECUTAR_BAT + ' ' + shlex.quote(caminho_do_programa) + ' "$@"\n')
    os.chmod(destino, 0o755)


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
                    criar_entrada_de_programa(pasta_nova, nome_no_path, pasta + '/' + nome, extensao.lower())


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


ctypes.CDLL(None).prctl(PR_SET_CHILD_SUBREAPER, 1, 0, 0, 0)
signal.signal(signal.SIGHUP, guardar_sinal_de_fim)
signal.signal(signal.SIGTERM, guardar_sinal_de_fim)
signal.signal(signal.SIGINT, ignorar_interrupcao)

entrada = criar_entrada_do_usuario()
ambiente = json.loads(base64.b64decode(sys.argv[2]).decode('utf-8'))
os.environ.update(ambiente['variaveis'])
os.environ['PATH'] = os.environ.get('PATH', '') + ':' + preparar_path_do_windows(ambiente['pathDoWindows'])
comando = subprocess.Popen(sys.argv[3:], stdin=entrada)
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
