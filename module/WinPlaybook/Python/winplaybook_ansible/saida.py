import io
import os
import re
import sys

from .comum import eh_programa_do_ansible, raiz_de_montagem

CARACTERE_DE_CAMINHO = rb'[^\s\'"\],:;=()]'
CAMINHO_DA_DISTRIBUICAO = re.compile(rb'(?<![\w/.~-])/(?:home|root|tmp|usr|etc|opt|var|srv)(?:/' + CARACTERE_DE_CAMINHO + rb'*)?')
LISTA_DE_CAMINHOS = re.compile(rb'(?<![\w/.~-])/' + CARACTERE_DE_CAMINHO + rb'*(?::/' + CARACTERE_DE_CAMINHO + rb'*)+')
ASPAS_SEM_ESCAPE = re.compile(rb'(?<!\\)"')
CONTINUACAO_DO_CAMINHO = re.compile(rb'[ \]](' + CARACTERE_DE_CAMINHO + rb'*)')
PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES = b'/opt/winplaybook/exec/'
PROGRAMAS_DO_NO_DE_CONTROLE = ('ansible-config', 'ansible-doc', 'ansible-galaxy')
programa_mostra_caminhos_da_distribuicao = []


def padrao_da_montagem():
    raiz = re.escape(raiz_de_montagem().encode())
    return re.compile(rb'(?<![\w/.-])' + raiz + rb'/(?:unc/(?P<servidor>[^/\s\'"]+)/(?P<compartilhamento>[^/\s\'"]+)|(?P<unidade>[a-z])(?![\w.-]))(?P<resto>(?:/' + CARACTERE_DE_CAMINHO + rb'*)?)')


def esta_entre_aspas(texto, inicio):
    if texto[inicio - 1:inicio] == b"'":
        return True
    comeco_da_linha = texto.rfind(b'\n', 0, inicio) + 1
    return len(ASPAS_SEM_ESCAPE.findall(texto, comeco_da_linha, inicio)) % 2 == 1


def formatar_caminho_do_windows(caminho, entre_aspas):
    caminho = caminho.replace(b'/', b'\\')
    if entre_aspas:
        return caminho.replace(b'\\', b'\\\\')
    return caminho


def caminho_pode_continuar(caminho, continuacao):
    pasta, _, nome = caminho.rpartition(b'/')
    if not os.path.isdir(pasta or b'/'):
        return False
    if b'/' in continuacao:
        return True
    try:
        return any(entrada.startswith(nome) for entrada in os.listdir(pasta or b'/'))
    except OSError:
        return False


def fim_do_caminho(texto, caminho, fim):
    while True:
        continuacao = CONTINUACAO_DO_CAMINHO.match(texto, fim)
        if not continuacao or not continuacao.group(1):
            return fim
        candidato = caminho + continuacao.group(0)
        if not caminho_pode_continuar(candidato, continuacao.group(0)):
            return fim
        caminho = candidato
        fim = continuacao.end()


def substituir_caminhos(padrao, dados, mostrar):
    partes = []
    posicao = 0
    for ocorrencia in padrao.finditer(dados):
        if ocorrencia.start() < posicao:
            continue
        fim = fim_do_caminho(dados, ocorrencia.group(0), ocorrencia.end())
        partes.append(dados[posicao:ocorrencia.start()])
        partes.append(mostrar(ocorrencia, dados[ocorrencia.end():fim]))
        posicao = fim
    partes.append(dados[posicao:])
    return b''.join(partes)

def caminho_da_montagem_no_windows(ocorrencia):
    if ocorrencia.group('servidor'):
        inicio = b'//' + ocorrencia.group('servidor') + b'/' + ocorrencia.group('compartilhamento')
    else:
        inicio = ocorrencia.group('unidade').upper() + b':'
    return inicio + (ocorrencia.group('resto') or b'/')


def eh_caminho_do_windows(caminho):
    if padrao_da_montagem().fullmatch(caminho):
        return True
    return mostra_caminhos_da_distribuicao() and bool(CAMINHO_DA_DISTRIBUICAO.fullmatch(caminho))


def separar_lista_de_caminhos(ocorrencia):
    lista = ocorrencia.group(0)
    if not all(eh_caminho_do_windows(caminho) for caminho in lista.split(b':')):
        return lista
    return lista.replace(b':/', b';/')


def traduzir_caminhos_da_montagem(dados):
    def mostrar(ocorrencia, continuacao):
        return formatar_caminho_do_windows(caminho_da_montagem_no_windows(ocorrencia) + continuacao, esta_entre_aspas(ocorrencia.string, ocorrencia.start()))

    return substituir_caminhos(padrao_da_montagem(), dados, mostrar)


def mostra_caminhos_da_distribuicao():
    if not programa_mostra_caminhos_da_distribuicao:
        argumentos = getattr(sys, 'argv', ['']) or ['']
        programa = os.path.basename(argumentos[0] or '')
        mostra = programa in PROGRAMAS_DO_NO_DE_CONTROLE or (programa == 'ansible' and '--version' in argumentos[1:])
        programa_mostra_caminhos_da_distribuicao.append(mostra)
    return programa_mostra_caminhos_da_distribuicao[0]


def caminho_da_distribuicao_no_windows(caminho):
    real = os.path.realpath(caminho)
    raiz = raiz_de_montagem().encode() + b'/'
    if real.startswith(PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES):
        real = raiz + real[len(PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES):]
    ocorrencia = padrao_da_montagem().fullmatch(real)
    if ocorrencia:
        return caminho_da_montagem_no_windows(ocorrencia)
    distribuicao = os.environ.get('WSL_DISTRO_NAME')
    if not distribuicao:
        return None
    return b'//wsl.localhost/' + distribuicao.encode() + caminho


def traduzir_caminhos_da_distribuicao(dados):
    def mostrar(ocorrencia, continuacao):
        caminho = caminho_da_distribuicao_no_windows(ocorrencia.group(0) + continuacao)
        if caminho is None:
            return ocorrencia.group(0) + continuacao
        return formatar_caminho_do_windows(caminho, esta_entre_aspas(ocorrencia.string, ocorrencia.start()))

    return substituir_caminhos(CAMINHO_DA_DISTRIBUICAO, dados, mostrar)


def traduzir_saida(dados):
    dados = LISTA_DE_CAMINHOS.sub(separar_lista_de_caminhos, dados)
    if mostra_caminhos_da_distribuicao():
        dados = traduzir_caminhos_da_distribuicao(dados)
    return traduzir_caminhos_da_montagem(dados)


class SaidaComCaminhosDoWindows(io.BufferedIOBase):
    def __init__(self, original):
        self._original = original

    def write(self, dados):
        tamanho = len(dados)
        if eh_programa_do_ansible():
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


AJUSTES = {}


def instalar():
    sys.stdout = mostrar_saida_com_caminhos_do_windows(sys.stdout)
    sys.stderr = mostrar_saida_com_caminhos_do_windows(sys.stderr)
