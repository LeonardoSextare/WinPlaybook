# Rede

A distribuição do WinPlaybook tem uma rede própria, separada da rede do Windows.
Enquanto um comando está rodando, o WinPlaybook liga uma ponte entre as duas, e
o Ansible alcança o que o Windows alcança.

## Os servidores

As conexões TCP do Ansible, como o SSH, o WinRM e o HTTPS, saem pelo Windows.
Quem conecta é o Windows, então valem as rotas, a VPN e o firewall dele, e o
Ansible chega aos mesmos servidores que o PowerShell. Isso inclui as máquinas
virtuais do Hyper-V ligadas ao Default Switch, que a rede própria do WSL não
alcança.

!!! info "Como uma conexão recusada aparece"

    Quando o servidor recusa a conexão, o Ansible vê a conexão ser
    interrompida (`Connection reset by peer`), e não recusada
    (`Connection refused`). Um servidor que não responde continua dando
    _timeout_.

## O localhost

No Linux, o `localhost` de uma tarefa é a própria máquina do Ansible. No
WinPlaybook, essa máquina é a distribuição, e um serviço que você roda no
Windows, como uma API em desenvolvimento ou um container do Docker Desktop,
não estaria nela.

Por isso, enquanto um comando está rodando, o WinPlaybook mantém uma ponte:
quando nenhum serviço da distribuição atende uma conexão ao `localhost`, ela é
encaminhada para o `localhost` do Windows. Assim, um `wait_for` ou um `uri` para `localhost:8080` chega ao
serviço do Windows.

!!! info "Regras da ponte"

    - Se a distribuição também usa a porta, a conexão fica na distribuição.
    - Uma porta fechada no Windows continua recusando a conexão.
    - A ponte existe só enquanto um comando do WinPlaybook roda.
    - Vários comandos ao mesmo tempo, como o do VS Code e o do terminal,
      dividem a ponte, e cada conexão dura enquanto o comando que a abriu roda.

---

## O localhost_windows

O `localhost_windows` usa essa ponte. O Ansible se conecta por SSH ao
`127.0.0.1`, na porta `47022`, e a ponte leva a conexão ao serviço
`WinPlaybookSshd` do Windows, que só escuta no `127.0.0.1`, então a porta não
fica acessível pela rede. Veja [Configurar o próprio Windows](localhost-windows.md).

---

## Proxy

O `HTTPS_PROXY`, o `HTTP_PROXY` e o `NO_PROXY` do Windows são repassados aos
comandos, como as outras variáveis de ambiente. Veja
[Variáveis de ambiente](environment-variables.md).
