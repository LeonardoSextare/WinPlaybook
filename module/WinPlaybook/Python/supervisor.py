import atexit
import base64
import ctypes
import glob
import hashlib
import ipaddress
import json
import os
import re
import shlex
import shutil
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import tomllib
import threading
import time

PR_SET_CHILD_SUBREAPER = 36
PASTA_DO_PATH_DO_WINDOWS = os.path.expanduser('~/.cache/winplaybook/path-do-windows')
UV = os.path.expanduser('~/.local/bin/uv')
PACOTES_DO_ANSIBLE = ('ansible', 'ansible-core')
PACOTE_DO_HOOK = 'winplaybook_ansible'
CHAVE_DO_LOCALHOST_WINDOWS = os.path.expanduser('~/.config/winplaybook/localhost_windows')
KNOWN_HOSTS_DO_LOCALHOST_WINDOWS = os.path.expanduser('~/.config/winplaybook/known_hosts_localhost_windows')
COMANDO_DO_AMBIENTE_PYTHON = re.compile(r'^(python[0-9.]*|pip[0-9.]*|pydoc[0-9.]*|activate.*|deactivate)$')
NFT_DA_PONTE = '/usr/local/lib/winplaybook/nft'
PORTA_DA_PONTE = 47999
SO_ORIGINAL_DST = 80
REGRAS_DA_PONTE = '''table inet winplaybook
delete table inet winplaybook
table inet winplaybook {
    set portas_do_windows { type inet_service; }
    chain saida {
        type nat hook output priority -100; policy accept;
        ip daddr 127.0.0.1 tcp dport @portas_do_windows redirect to :47999
        ip6 daddr ::1 tcp dport @portas_do_windows redirect to :47999
        oifname != "lo" meta l4proto tcp redirect to :47999
    }
}
'''
REGRAS_SEM_A_PONTE = 'table inet winplaybook\ndelete table inet winplaybook\n'
portas_do_windows = []
processos_da_ponte = []
portas_mudaram = threading.Event()
lista_de_portas_recebida = [False]
ponte_pronta = threading.Event()
EXECUTAR_WINDOWS = '/usr/local/lib/winplaybook/executar-windows'
PRIORIDADE_DAS_EXTENSOES = {'.com': 0, '.exe': 1, '.bat': 2, '.cmd': 3}
NOME_CURTO_RESERVADO = re.compile(r'^(python|pip|py)[0-9.]*$', re.IGNORECASE)
CAMINHO_DO_WINDOWS = re.compile(r'^[A-Za-z]:[\\/]')
LINHA_DO_SSH = re.compile(r'^(\s*)(IdentityFile|CertificateFile|UserKnownHostsFile|GlobalKnownHostsFile|IdentityAgent|ControlPath|Include|RevokedHostKeys|ProxyCommand)(\s*=\s*|\s+)(.*?)\s*$', re.IGNORECASE)
PROGRAMA_DO_PROXY = re.compile(r'^("[^"]+"|\S+)')
LINHA_DO_GIT = re.compile(r'^(\s*)([A-Za-z][\w-]*)(\s*=\s*)(.*?)\s*$')
CAMINHO_DO_WINDOWS_NO_GIT = re.compile(r'^"?[A-Za-z]:(\\\\|\\|/)')
HELPER_DO_WINDOWS = re.compile(r'^"?(manager(-core)?|.*git-credential-manager(\.exe)?)"?$', re.IGNORECASE)
PACOTE_DE_CERTIFICADOS_DO_SISTEMA = '/etc/ssl/certs/ca-certificates.crt'
VARIAVEIS_DE_CERTIFICADOS = ('SSL_CERT_FILE', 'REQUESTS_CA_BUNDLE', 'CURL_CA_BUNDLE', 'GIT_SSL_CAINFO')
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


def preparar_certificados(certificados_do_windows):
    destino = os.path.expanduser('~/.cache/winplaybook/certificados.pem')
    marca = destino + '.origem'
    try:
        impressao = os.path.basename(certificados_do_windows) + ' ' + str(os.stat(PACOTE_DE_CERTIFICADOS_DO_SISTEMA).st_mtime_ns)
        with open(marca, encoding='utf-8') as arquivo:
            esta_atualizado = arquivo.read() == impressao and os.path.isfile(destino)
    except FileNotFoundError:
        esta_atualizado = False
    except OSError:
        return
    if not esta_atualizado:
        try:
            with open(PACOTE_DE_CERTIFICADOS_DO_SISTEMA, 'rb') as arquivo:
                do_sistema = arquivo.read()
            with open(certificados_do_windows, 'rb') as arquivo:
                do_windows = arquivo.read()
        except OSError:
            return
        os.makedirs(os.path.dirname(destino), exist_ok=True)
        for caminho, conteudo in ((destino, do_sistema.rstrip(b'\n') + b'\n' + do_windows), (marca, impressao.encode('utf-8'))):
            temporario = caminho + '.' + str(os.getpid())
            with open(temporario, 'wb') as arquivo:
                arquivo.write(conteudo)
            os.replace(temporario, caminho)
    for nome in VARIAVEIS_DE_CERTIFICADOS:
        os.environ.setdefault(nome, destino)


def depende_do_ansible(dependencias):
    for dependencia in dependencias:
        nome = re.match(r'\s*([A-Za-z0-9._-]+)', dependencia) if isinstance(dependencia, str) else None
        if nome and nome.group(1).lower().replace('_', '-') in PACOTES_DO_ANSIBLE:
            return True
    return False


def achar_projeto_do_ansible(pasta):
    while True:
        caminho = os.path.join(pasta, 'pyproject.toml')
        if os.path.isfile(caminho):
            try:
                with open(caminho, 'rb') as arquivo:
                    configuracao = tomllib.load(arquivo)
            except (OSError, tomllib.TOMLDecodeError):
                return None
            projeto = configuracao.get('project', {})
            grupos = list(projeto.get('optional-dependencies', {}).values()) + list(configuracao.get('dependency-groups', {}).values())
            dependencias = list(projeto.get('dependencies', [])) + [item for grupo in grupos for item in grupo]
            return pasta if 'project' in configuracao and depende_do_ansible(dependencias) else None
        pai = os.path.dirname(pasta)
        if pai == pasta:
            return None
        pasta = pai


def gravar_se_mudou(caminho, conteudo):
    try:
        with open(caminho, 'rb') as arquivo:
            if arquivo.read() == conteudo:
                return
    except OSError:
        pass
    with open(caminho, 'wb') as arquivo:
        arquivo.write(conteudo)


def instalar_modulo_do_winplaybook(ambiente_do_projeto):
    origens = glob.glob(os.path.expanduser('~/.local/share/uv/tools/ansible/lib/python*/site-packages/' + PACOTE_DO_HOOK))
    destinos = glob.glob(ambiente_do_projeto + '/lib/python*/site-packages')
    if not origens or not destinos:
        return
    pasta_do_pacote = os.path.join(destinos[0], PACOTE_DO_HOOK)
    os.makedirs(pasta_do_pacote, exist_ok=True)
    for caminho_de_origem in glob.glob(os.path.join(origens[0], '*.py')):
        with open(caminho_de_origem, 'rb') as arquivo:
            gravar_se_mudou(os.path.join(pasta_do_pacote, os.path.basename(caminho_de_origem)), arquivo.read())
    gravar_se_mudou(os.path.join(destinos[0], 'winplaybook.pth'), ('import ' + PACOTE_DO_HOOK + '\n').encode())
    try:
        os.remove(os.path.join(destinos[0], 'winplaybook_caminhos_do_windows.py'))
    except OSError:
        pass


def listar_comandos_do_projeto(ambiente_do_projeto, caminho_da_lista):
    pasta = ambiente_do_projeto + '/bin'
    comandos = sorted(nome for nome in os.listdir(pasta) if not COMANDO_DO_AMBIENTE_PYTHON.match(nome) and os.path.isfile(os.path.join(pasta, nome)) and os.access(os.path.join(pasta, nome), os.X_OK))
    with open(caminho_da_lista, 'w', encoding='utf-8') as arquivo:
        arquivo.write('\n'.join(comandos) + '\n')


def preparar_ambiente_do_projeto(caminho_da_lista_de_comandos):
    projeto = achar_projeto_do_ansible(os.getcwd())
    if projeto is None:
        return
    ambiente_do_projeto = os.path.expanduser('~/.cache/winplaybook/projetos/') + hashlib.sha256(projeto.encode()).hexdigest()[:16]
    os.environ['UV_PROJECT_ENVIRONMENT'] = ambiente_do_projeto
    sincronizacao = subprocess.run([UV, 'sync', '--quiet', '--project', projeto], stdin=subprocess.DEVNULL)
    if sincronizacao.returncode != 0:
        sys.exit(sincronizacao.returncode)
    instalar_modulo_do_winplaybook(ambiente_do_projeto)
    if caminho_da_lista_de_comandos:
        listar_comandos_do_projeto(ambiente_do_projeto, caminho_da_lista_de_comandos)
    pasta_do_uv = os.path.expanduser('~/.cache/winplaybook/uv')
    os.makedirs(pasta_do_uv, exist_ok=True)
    for programa in ('uv', 'uvx'):
        try:
            os.symlink(os.path.join(os.path.dirname(UV), programa), os.path.join(pasta_do_uv, programa))
        except FileExistsError:
            pass
    pastas = [pasta_do_uv if pasta == os.path.dirname(UV) else pasta for pasta in os.environ.get('PATH', '').split(':')]
    os.environ['PATH'] = ':'.join([ambiente_do_projeto + '/bin'] + pastas)
    os.environ['VIRTUAL_ENV'] = ambiente_do_projeto


def ler_portas_da_distribuicao():
    portas = set()
    for caminho in ('/proc/net/tcp', '/proc/net/tcp6'):
        try:
            with open(caminho) as tabela:
                next(tabela)
                for linha in tabela:
                    campos = linha.split()
                    if campos[3] == '0A':
                        portas.add(int(campos[1].rsplit(':', 1)[1], 16))
        except (OSError, StopIteration):
            pass
    return portas


def aplicar_regras_de_rede(regras):
    subprocess.run([NFT_DA_PONTE, '-f', '-'], input=regras.replace('\r', ''), text=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def acompanhar_portas_do_windows(relay):
    processo = subprocess.Popen([relay, 'portas'], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    processos_da_ponte.append(processo)
    for linha in processo.stdout:
        portas_do_windows[:] = [int(porta) for porta in linha.split()]
        lista_de_portas_recebida[0] = True
        portas_mudaram.set()


def atualizar_portas_da_ponte():
    aplicadas = None
    while True:
        portas = sorted(set(portas_do_windows) - ler_portas_da_distribuicao() - {PORTA_DA_PONTE})
        if portas != aplicadas:
            comandos = 'flush set inet winplaybook portas_do_windows\n'
            if portas:
                comandos += 'add element inet winplaybook portas_do_windows { ' + ', '.join(str(porta) for porta in portas) + ' }\n'
            aplicar_regras_de_rede(comandos)
            aplicadas = portas
        if lista_de_portas_recebida[0]:
            ponte_pronta.set()
        portas_mudaram.wait(1)
        portas_mudaram.clear()


def copiar_conexao(ler, escrever, fechar):
    try:
        while True:
            dados = ler(65536)
            if not dados:
                break
            escrever(dados)
    except OSError:
        pass
    finally:
        try:
            fechar()
        except OSError:
            pass


def escrever_no_relay(processo):
    def escrever(dados):
        processo.stdin.write(dados)
        processo.stdin.flush()
    return escrever


def fechar_conexao_do_relay(conexao, processo):
    try:
        falhou = processo.wait(timeout=0.5) != 0
    except subprocess.TimeoutExpired:
        falhou = False
    if falhou:
        conexao.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER, struct.pack('ii', 1, 0))
        conexao.shutdown(socket.SHUT_RD)
        return
    conexao.shutdown(socket.SHUT_WR)


def atender_conexao(conexao, familia, relay):
    with conexao:
        nivel = socket.SOL_IP if familia == socket.AF_INET else socket.IPPROTO_IPV6
        endereco = conexao.getsockopt(nivel, SO_ORIGINAL_DST, 16 if familia == socket.AF_INET else 28)
        porta = struct.unpack('!H', endereco[2:4])[0]
        if familia == socket.AF_INET:
            destino = ipaddress.ip_address(endereco[4:8])
        else:
            destino = ipaddress.ip_address(endereco[8:24])
        argumentos = [relay, 'conectar', str(porta)]
        if not destino.is_loopback:
            argumentos.append(str(destino))
        processo = subprocess.Popen(argumentos, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        do_windows = threading.Thread(target=copiar_conexao, args=(processo.stdout.read1, conexao.sendall, lambda: fechar_conexao_do_relay(conexao, processo)), daemon=True)
        do_windows.start()
        copiar_conexao(conexao.recv, escrever_no_relay(processo), processo.stdin.close)
        do_windows.join()
        processo.wait()


def aceitar_conexoes(servidor, familia, relay):
    while True:
        conexao, _ = servidor.accept()
        threading.Thread(target=atender_conexao, args=(conexao, familia, relay), daemon=True).start()


def abrir_servidores_da_ponte():
    servidores = []
    for familia, endereco in ((socket.AF_INET, '127.0.0.1'), (socket.AF_INET6, '::1')):
        servidor = None
        try:
            servidor = socket.socket(familia, socket.SOCK_STREAM)
            if familia == socket.AF_INET6:
                servidor.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
            servidor.bind((endereco, PORTA_DA_PONTE))
            servidor.listen(128)
            servidores.append((servidor, familia))
        except OSError:
            if servidor is not None:
                servidor.close()
    return servidores


def assumir_a_ponte_de_rede(relay):
    servidores = abrir_servidores_da_ponte()
    if not servidores:
        ponte_pronta.set()
    while not servidores:
        time.sleep(1)
        servidores = abrir_servidores_da_ponte()
    aplicar_regras_de_rede(REGRAS_DA_PONTE)
    atexit.register(encerrar_a_ponte_de_rede)
    for servidor, familia in servidores:
        threading.Thread(target=aceitar_conexoes, args=(servidor, familia, relay), daemon=True).start()
    threading.Thread(target=acompanhar_portas_do_windows, args=(relay,), daemon=True).start()
    atualizar_portas_da_ponte()


def encerrar_a_ponte_de_rede():
    aplicar_regras_de_rede(REGRAS_SEM_A_PONTE)
    for processo in processos_da_ponte:
        processo.kill()


def apagar_regras_sem_dono():
    servidores = abrir_servidores_da_ponte()
    if servidores:
        aplicar_regras_de_rede(REGRAS_SEM_A_PONTE)
    for servidor, _ in servidores:
        servidor.close()


def iniciar_ponte_de_rede(relay):
    if not os.access(NFT_DA_PONTE, os.X_OK):
        return
    if not (relay and os.access(relay, os.X_OK)):
        apagar_regras_sem_dono()
        return
    threading.Thread(target=assumir_a_ponte_de_rede, args=(relay,), daemon=True).start()
    ponte_pronta.wait(5)


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

tempos_das_etapas = []
inicio_da_etapa = [time.monotonic()]


def marcar_etapa(nome):
    agora = time.monotonic()
    tempos_das_etapas.append(nome + ': ' + str(int((agora - inicio_da_etapa[0]) * 1000)) + ' ms')
    inicio_da_etapa[0] = agora


def registrar_tempos_no_log(caminho_do_log):
    marcar_etapa('comando')
    linha = time.strftime('%Y-%m-%dT%H:%M:%S%z') + ' [DEBUG] [supervisor ' + str(os.getpid()) + '] ' + os.path.basename(sys.argv[1]) + ': ' + ', '.join(tempos_das_etapas)
    try:
        os.makedirs(os.path.dirname(caminho_do_log), exist_ok=True)
        with open(caminho_do_log, 'a', encoding='utf-8') as arquivo:
            arquivo.write(linha + '\n')
    except OSError:
        pass


entrada = criar_entrada_do_usuario()
ambiente = json.loads(os.environ.pop('WINPLAYBOOK_ENVIRONMENT'))
os.environ.update(ambiente['variaveis'])
if ambiente.get('log'):
    atexit.register(registrar_tempos_no_log, ambiente['log'])
os.environ['PATH'] = os.environ.get('PATH', '') + ':' + preparar_path_do_windows(ambiente['pathDoWindows'])
marcar_etapa('path do Windows')
preparar_config_do_ssh()
marcar_etapa('config do ssh')
preparar_config_do_git(ambiente['pathDoWindows'])
marcar_etapa('config do git')
if os.path.basename(sys.argv[1]) == 'ansible-vault' and not os.environ.get('EDITOR') and not os.environ.get('VISUAL'):
    os.environ['EDITOR'] = 'notepad.exe'
preparar_certificados(ambiente['certificadosDoWindows'])
marcar_etapa('certificados')
preparar_ambiente_do_projeto(ambiente.get('comandosDoProjeto'))
marcar_etapa('ambiente do projeto')
if ambiente.get('localhostWindows'):
    os.environ['WINPLAYBOOK_LOCALHOST_WINDOWS'] = json.dumps(dict(ambiente['localhostWindows'], chave=CHAVE_DO_LOCALHOST_WINDOWS, knownHosts=KNOWN_HOSTS_DO_LOCALHOST_WINDOWS))
iniciar_ponte_de_rede(ambiente.get('relayDeRede'))
marcar_etapa('ponte de rede')
mensagem_de_comando_ausente = os.environ.pop('WINPLAYBOOK_COMMAND_NOT_FOUND_MESSAGE', '')
pastas_da_distribuicao = ':'.join(pasta for pasta in os.environ.get('PATH', '').split(':') if pasta != PASTA_DO_PATH_DO_WINDOWS)
if shutil.which(sys.argv[1], path=pastas_da_distribuicao) is None:
    print(mensagem_de_comando_ausente, file=sys.stderr)
    sys.exit(127)
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
