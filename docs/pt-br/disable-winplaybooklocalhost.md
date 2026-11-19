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

- Apaga o serviço `WinPlaybookSshd` e as pastas `C:\ProgramData\WinPlaybook\ssh`
  e `C:\ProgramData\WinPlaybook\openssh`.

Precisa de administrador. O `Uninstall-WinPlaybook` também desliga o
`localhost_windows`.
