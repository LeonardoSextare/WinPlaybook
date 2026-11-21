import json
import os

HOST_DA_MAQUINA_WINDOWS = 'localhost_windows'


def criar_host_da_maquina_windows():
    try:
        configuracao = json.loads(os.environ.get('WINPLAYBOOK_LOCALHOST_WINDOWS', ''))
    except ValueError:
        return None
    from ansible.inventory.host import Host
    host = Host(HOST_DA_MAQUINA_WINDOWS)
    host.address = HOST_DA_MAQUINA_WINDOWS
    host.implicit = True
    variaveis = {
        'ansible_connection': 'ssh',
        'ansible_shell_type': configuracao.get('shell', 'cmd'),
    }
    for nome, valor in variaveis.items():
        host.set_variable(nome, valor)
    return host


def ajustar_dados_do_inventario(modulo):
    get_host = modulo.InventoryData.get_host

    def get_host_com_a_maquina_windows(self, hostname):
        host = get_host(self, hostname)
        if host is None and hostname == HOST_DA_MAQUINA_WINDOWS:
            if not hasattr(self, '_host_da_maquina_windows'):
                self._host_da_maquina_windows = criar_host_da_maquina_windows()
            host = self._host_da_maquina_windows
        return host

    modulo.InventoryData.get_host = get_host_com_a_maquina_windows


def ajustar_gerenciador_de_inventario(modulo):
    enumerate_matches = modulo.InventoryManager._enumerate_matches

    def enumerate_matches_com_a_maquina_windows(self, pattern):
        if pattern == HOST_DA_MAQUINA_WINDOWS and pattern not in self._inventory.hosts:
            host = self._inventory.get_host(pattern)
            if host is not None:
                return [host]
        return enumerate_matches(self, pattern)

    modulo.InventoryManager._enumerate_matches = enumerate_matches_com_a_maquina_windows


AJUSTES = {
    'ansible.inventory.data': ajustar_dados_do_inventario,
    'ansible.inventory.manager': ajustar_gerenciador_de_inventario,
}


def instalar():
    pass
