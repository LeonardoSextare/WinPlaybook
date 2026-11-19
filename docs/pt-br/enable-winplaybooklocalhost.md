# Enable-WinPlaybookLocalhost

Liga o `localhost_windows`, o host que faz os _playbooks_ configurarem a
própria máquina Windows, com os módulos `ansible.windows`.

## Sintaxe

```powershell
Enable-WinPlaybookLocalhost [-WhatIf] [-Confirm]
```

---

## Exemplos

```powershell
Enable-WinPlaybookLocalhost
```

---

## Observações

- Precisa de administrador. Se o PowerShell não estiver aberto como
  administrador, o Windows pede a aprovação.
- Na primeira vez, o comando baixa o OpenSSH da release oficial da Microsoft no
  GitHub, com poucos MB.

---

## O que altera

- Baixa o OpenSSH para `C:\ProgramData\WinPlaybook\openssh`, uma pasta só do
  WinPlaybook. Nada é instalado no Windows: o recurso OpenSSH Server, o
  `ssh-agent` e o cliente `ssh` ficam como estão.
- Cria o serviço `WinPlaybookSshd`, com a configuração em
  `C:\ProgramData\WinPlaybook\ssh`. Ele só escuta no `127.0.0.1`, na porta
  `47022`, e só aceita a chave que fica na distribuição, sem senha, para o seu
  usuário.
- Cria a chave na distribuição.

Veja [Configurar o próprio Windows](localhost-windows.md) e
[Disable-WinPlaybookLocalhost](disable-winplaybooklocalhost.md).
