# Install-WinPlaybook

Instala o Ansible numa distribuição WSL própria e cria os comandos dele no
Windows. Rodar de novo atualiza o Ansible e os comandos e mantém a
distribuição.

## Sintaxe

```powershell
Install-WinPlaybook [-Path <string>] [-PowerShell <Desktop | Core>] [-AnsibleVersion <string>] [-PythonPackage <string[]>] [-EnableLocalhost] [-WhatIf] [-Confirm]
```

---

## Parâmetros

### -Path

A pasta onde a pasta `WinPlaybook` é criada. Os comandos ficam em
`<Path>\WinPlaybook\bin`.

Padrão: `%LOCALAPPDATA%\WinPlaybook\bin`.

### -PowerShell

O PowerShell que os comandos `.exe` abrem: `Desktop`, o Windows PowerShell
5.1, que abre mais rápido, ou `Core`, o PowerShell 7.

Padrão: o da instalação anterior ou, na primeira, o PowerShell que roda o
comando.

### -AnsibleVersion

A versão do pacote `ansible`, como `13.0.0` ou `13.*`. Uma versão vazia
(`''`) volta para a mais nova.

Padrão: a da instalação anterior ou, sem uma escolha, a mais nova.

### -PythonPackage

Os pacotes Python que entram junto com o Ansible, no formato do pip, como
`boto3` ou `netaddr>=1.0`. Os comandos desses pacotes ganham um comando no
Windows. Uma lista vazia (`@()`) tira os pacotes.

Padrão: os da instalação anterior.

### -EnableLocalhost

Liga o `localhost_windows` sem perguntar. Sem esse parâmetro, a instalação pergunta
uma única vez, num terminal interativo.

---

## Exemplos

```powershell
Install-WinPlaybook
```

```powershell
Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3', 'netaddr'
```

```powershell
Install-WinPlaybook -Path 'C:\Tools' -PowerShell Desktop
```

---

## O que altera

- Cria a distribuição WSL `WinPlaybook`, na primeira vez.
- Cria os comandos em `<Path>\WinPlaybook\bin` e põe a pasta no `PATH` do
  usuário.
- Cria as pastas `.ansible\collections` e `.ansible\roles` e, quando não
  existe, a pasta `.ssh`, no seu perfil.
- Acrescenta a linha do autocomplete aos perfis do PowerShell.

Veja [O que o WinPlaybook altera no sistema](system-changes.md).
