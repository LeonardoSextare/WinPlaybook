# Rede

A distribuição do WinPlaybook tem uma rede própria, separada da rede do Windows. Para
os servidores da rede e da internet, isso não muda nada: o Ansible chega até eles
do mesmo jeito que o Windows. A diferença está no `localhost`.

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
