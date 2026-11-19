import os
import re

from .comum import converter_caminho

LISTA_COM_CAMINHO_DO_WINDOWS = re.compile(r'(^|;)\s*[A-Za-z]:[\\/]')
CAMINHO_DO_WINDOWS_SEM_ASPAS = re.compile(r'((?:^|(?<=[\s=]))[A-Za-z]:)(\\[^\s\'"]*)')
TIPOS_DE_CAMINHO = ('path', 'tmppath', 'temppath', 'tmp')
expanduser_original = os.path.expanduser


def expanduser(caminho):
    return expanduser_original(converter_caminho(caminho))


def ajustar_data_loader(modulo):
    data_loader = modulo.DataLoader
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
        if isinstance(value, str) and value_type in TIPOS_DE_CAMINHO:
            value = converter_caminho(value)
        elif isinstance(value, str) and value_type == 'pathlist':
            value = ','.join(converter_caminho(item.strip()) for item in value.split(','))
        elif isinstance(value, str) and value_type == 'pathspec':
            separador = ';' if LISTA_COM_CAMINHO_DO_WINDOWS.search(value) or ';' in value else ':'
            value = ':'.join(converter_caminho(item.strip()) for item in value.split(separador))
        return ensure_type(value, value_type, *args, **kwargs)

    modulo.ensure_type = ensure_type_com_windows


def proteger_barras(ocorrencia):
    return ocorrencia.group(1) + ocorrencia.group(2).replace('\\', '\\\\')


def ajustar_shlex(modulo):
    shlex_split = modulo.shlex_split

    def shlex_split_com_windows(texto, *args, **kwargs):
        return shlex_split(CAMINHO_DO_WINDOWS_SEM_ASPAS.sub(proteger_barras, texto), *args, **kwargs)

    modulo.shlex_split = shlex_split_com_windows


AJUSTES = {
    'ansible.parsing.dataloader': ajustar_data_loader,
    'ansible.config.manager': ajustar_gerenciador_de_configuracao,
    'ansible.utils.shlex': ajustar_shlex,
}


def instalar():
    os.path.expanduser = expanduser
