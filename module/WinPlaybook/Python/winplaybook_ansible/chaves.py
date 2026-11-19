import hashlib
import os

PASTA_DAS_CHAVES = os.path.join('~', '.cache', 'winplaybook', 'chaves')


def caminho_da_copia_protegida(chave):
    caminho = os.path.realpath(os.path.expanduser(chave))
    try:
        permissao_aberta = os.stat(caminho).st_mode & 0o077
        if not permissao_aberta:
            return chave
        with open(caminho, 'rb') as arquivo:
            conteudo = arquivo.read()
        pasta = os.path.expanduser(PASTA_DAS_CHAVES)
        os.makedirs(pasta, mode=0o700, exist_ok=True)
        os.chmod(pasta, 0o700)
        copia = os.path.join(pasta, hashlib.sha256(caminho.encode()).hexdigest()[:16])
        descritor = os.open(copia, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(descritor, 'wb') as arquivo:
            arquivo.write(conteudo)
        os.chmod(copia, 0o600)
        return copia
    except OSError:
        return chave


def ajustar_plugins(modulo):
    plugin = modulo.AnsiblePlugin
    get_option = plugin.get_option

    def get_option_com_chave_protegida(self, opcao, *args, **kwargs):
        valor = get_option(self, opcao, *args, **kwargs)
        if opcao == 'private_key_file' and isinstance(valor, str) and valor:
            return caminho_da_copia_protegida(valor)
        return valor

    plugin.get_option = get_option_com_chave_protegida


AJUSTES = {
    'ansible.plugins': ajustar_plugins,
}


def instalar():
    pass
