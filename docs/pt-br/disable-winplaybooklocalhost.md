# Disable-WinPlaybookLocalhost

Desliga o `localhost_windows` e desfaz o que o `Enable-WinPlaybookLocalhost`
fez. Sem o `localhost_windows` ligado, nada muda.

## Sintaxe

```powershell
Disable-WinPlaybookLocalhost [-WhatIf] [-Confirm]
```

---

## Exemplos

```powershell
Disable-WinPlaybookLocalhost
```

---

## O que altera

- Apaga o serviço `WinPlaybookSshd` e a pasta `C:\ProgramData\WinPlaybook\ssh`.
- Desinstala o OpenSSH Server, se foi o WinPlaybook que o instalou.

Precisa de administrador. O `Uninstall-WinPlaybook` também desliga o
`localhost_windows`.
