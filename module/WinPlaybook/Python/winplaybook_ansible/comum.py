import os
import re
import sys

PROGRAMA_DO_ANSIBLE = re.compile(r'^ansible(-[a-z]+)?$')
CAMINHO_DO_WINDOWS = re.compile(r'^[A-Za-z]:[\\/]')
CAMINHO_DO_WINDOWS_EM_BYTES = re.compile(rb'^[A-Za-z]:[\\/]')
programa_eh_do_ansible = []


def raiz_de_montagem():
    return os.environ.get('WINPLAYBOOK_MOUNT_ROOT', '/mnt/').rstrip('/')


def converter_caminho(caminho):
    raiz = raiz_de_montagem()
    if isinstance(caminho, str) and CAMINHO_DO_WINDOWS.match(caminho):
        return raiz + '/' + caminho[0].lower() + caminho[2:].replace('\\', '/')
    if isinstance(caminho, bytes) and CAMINHO_DO_WINDOWS_EM_BYTES.match(caminho):
        return raiz.encode() + b'/' + caminho[0:1].lower() + caminho[2:].replace(b'\\', b'/')
    return caminho


def eh_programa_do_ansible():
    if not programa_eh_do_ansible:
        programa = os.path.basename(getattr(sys, 'argv', [''])[0] or '')
        programa_eh_do_ansible.append(bool(PROGRAMA_DO_ANSIBLE.match(programa)))
    return programa_eh_do_ansible[0]
