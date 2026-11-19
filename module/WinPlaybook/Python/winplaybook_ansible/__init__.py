import sys

from . import caminhos, chaves, localhost_windows, saida, scripts
from .importacao import AjusteDoAnsible

PARTES = (caminhos, chaves, saida, scripts, localhost_windows)

ajustes = {}
for parte in PARTES:
    ajustes.update(parte.AJUSTES)
    parte.instalar()
sys.meta_path.insert(0, AjusteDoAnsible(ajustes))
