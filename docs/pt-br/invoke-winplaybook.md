# Invoke-WinPlaybook

Roda um comando na distribuição do WinPlaybook, a partir da pasta atual, com
as mesmas conversões dos comandos do Ansible. Os comandos do Ansible no
Windows, como o `ansible-playbook`, chamam o `Invoke-WinPlaybook` por baixo.

## Sintaxe

```powershell
Invoke-WinPlaybook <comando> [<argumentos>]
```

---

## Parâmetros

### comando

O comando que roda na distribuição, como `ansible-playbook` ou `ssh-add`.

### argumentos

Os argumentos do comando. Eles chegam ao comando como o PowerShell os passou,
sem que um _shell_ os interprete. Os caminhos do Windows são convertidos para os
caminhos correspondentes na distribuição.

---

## Entrada

O que chega pelo _pipeline_ vai para a entrada padrão do comando, em UTF-8.

---

## Saída

A saída do comando. O código de saída fica no `$LASTEXITCODE`.

---

## Exemplos

```powershell
Invoke-WinPlaybook ansible-playbook -i inventario.yml site.yml
```

```powershell
'segredo' | Invoke-WinPlaybook ansible-vault encrypt_string --stdin-name senha
```

```powershell
Invoke-WinPlaybook ssh-add -l
```
