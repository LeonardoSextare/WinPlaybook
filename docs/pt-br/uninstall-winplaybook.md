# Uninstall-WinPlaybook

Desfaz tudo o que o WinPlaybook alterou no sistema e apaga a distribuição WSL
`WinPlaybook`, com tudo o que há nela.

## Sintaxe

```powershell
Uninstall-WinPlaybook [-WhatIf] [-Confirm]
```

---

## Parâmetros

### -Confirm

Num terminal interativo, o comando pede confirmação, com o não como padrão.
`-Confirm:$false` pula a pergunta.

### -WhatIf

Mostra o que o comando faria, sem alterar nada.

---

## Exemplos

```powershell
Uninstall-WinPlaybook
```

```powershell
Uninstall-WinPlaybook -Confirm:$false
```

---

## O que altera

- Desliga o `localhost_windows`, se ele está ligado.
- Desfaz as correções da extensão Ansible do VS Code.
- Apaga a distribuição, os comandos, a configuração e os logs.
- Tira a pasta dos comandos do `PATH` e a linha do autocomplete dos perfis do
  PowerShell.
- Apaga as pastas `.ansible\collections`, `.ansible\roles` e `.ssh` do perfil
  só se elas estiverem vazias.

O módulo continua instalado. Veja [Desinstalar o WinPlaybook](uninstall.md).
