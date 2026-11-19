import io
import os
import re
import sys

from .comum import eh_programa_do_ansible, raiz_de_montagem

CAMINHO_DA_DISTRIBUICAO = re.compile(rb'(?<![\w/.~-])/(?:home|root|tmp|usr|etc|opt|var|srv)(?:/[^\s\'"\],:;=()]*)?')
PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES = b'/opt/winplaybook/exec/'
PROGRAMAS_DO_NO_DE_CONTROLE = ('ansible-config', 'ansible-doc', 'ansible-galaxy')
programa_mostra_caminhos_da_distribuicao = []


def mostrar_caminho_do_windows(ocorrencia):
    if ocorrencia.group('servidor'):
        return b'//' + ocorrencia.group('servidor') + b'/' + ocorrencia.group('compartilhamento')
    return ocorrencia.group('unidade').upper() + b':'


def traduzir_saida(dados):
    raiz = re.escape(raiz_de_montagem().encode())
    padrao = rb'(?<![\w/.-])' + raiz + rb'/(?:unc/(?P<servidor>[^/\s\'"]+)/(?P<compartilhamento>[^/\s\'"]+)|(?P<unidade>[a-z])(?![\w.-]))'
    return re.sub(padrao, mostrar_caminho_do_windows, dados)


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
    raiz = raiz_de_montagem().encode() + b'/'
    if real.startswith(PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES):
        real = raiz + real[len(PASTA_DA_MONTAGEM_COM_EXECUCAO_EM_BYTES):]
    if real.startswith(raiz):
        return traduzir_saida(real)
    distribuicao = os.environ.get('WSL_DISTRO_NAME')
    return b'//wsl.localhost/' + distribuicao.encode() + caminho if distribuicao else caminho


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


AJUSTES = {}


def instalar():
    sys.stdout = mostrar_saida_com_caminhos_do_windows(sys.stdout)
    sys.stderr = mostrar_saida_com_caminhos_do_windows(sys.stderr)
