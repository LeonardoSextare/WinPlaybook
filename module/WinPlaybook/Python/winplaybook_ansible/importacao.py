import importlib.abc
import importlib.util


class CarregadorAjustado(importlib.abc.Loader):
    def __init__(self, original, ajuste):
        self._original = original
        self._ajuste = ajuste

    def create_module(self, especificacao):
        return self._original.create_module(especificacao)

    def exec_module(self, modulo):
        self._original.exec_module(modulo)
        self._ajuste(modulo)

    def __getattr__(self, nome):
        return getattr(self._original, nome)


class AjusteDoAnsible(importlib.abc.MetaPathFinder):
    def __init__(self, ajustes):
        self._ajustes = ajustes
        self._carregando = None

    def find_spec(self, nome, caminho, alvo=None):
        if nome not in self._ajustes or self._carregando == nome:
            return None
        self._carregando = nome
        try:
            especificacao = importlib.util.find_spec(nome)
        finally:
            self._carregando = None
        especificacao.loader = CarregadorAjustado(especificacao.loader, self._ajustes[nome])
        return especificacao
