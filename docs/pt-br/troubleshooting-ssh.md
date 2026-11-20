# Problemas de conexão e SSH

Comece testando o `ssh` do Windows no mesmo servidor:

```powershell
ssh deploy@192.168.0.10
```

Se o `ssh` do Windows também falha, o problema está na chave, no servidor ou
na rede, e não no WinPlaybook.

## Permission denied (publickey)

O servidor recusou a chave.

- Confira se a chave pública está no `~/.ssh/authorized_keys` do servidor.
- Confira o usuário. Sem um `ansible_user` no inventário, o Ansible usa o seu
  nome de usuário do Windows.
- Se a chave tem passphrase, ela precisa estar no agente SSH. Veja
  [Usar uma chave com passphrase](ssh.md#usar-uma-chave-com-passphrase).

---

## O Ansible pede a passphrase ou trava

O Ansible não responde ao pedido de passphrase. Adicione a chave ao agente
SSH do Windows e confira se o Ansible a enxerga:

```powershell
Invoke-WinPlaybook ssh-add -l
```

Se a saída diz que não há um agente, o serviço `ssh-agent` do Windows está
parado. Veja [Usar uma chave com passphrase](ssh.md#usar-uma-chave-com-passphrase).

---

## communication with agent failed

O WinPlaybook não conseguiu falar com o agente SSH do Windows. No fim da
saída, uma linha que começa com `WinPlaybook:` mostra o motivo. Se o agente
estava ocupado ou demorou a responder, rode o comando de novo. Se a falha
continua, reinicie o serviço `ssh-agent` do Windows:

```powershell
Restart-Service ssh-agent
```

---

## Host key verification failed

O servidor não está no `known_hosts`, ou mudou de chave. Conecte uma vez com o
`ssh` do Windows e aceite a chave. O Ansible usa o mesmo `known_hosts`.

Se o servidor foi reinstalado, tire a chave antiga:

```powershell
ssh-keygen -R 192.168.0.10
```

---

## Connection timed out ou No route to host

A distribuição do WinPlaybook não alcança o servidor.

- Numa VPN, confira se o `ssh` do Windows alcança o servidor. Algumas VPNs
  não deixam o tráfego do WSL passar. Nesse caso, veja a
  [solução de problemas do WSL](https://learn.microsoft.com/windows/wsl/troubleshooting).
- Se o servidor tem um nome que só o DNS da empresa resolve, teste com o IP.
