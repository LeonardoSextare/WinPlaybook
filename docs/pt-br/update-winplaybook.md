# Update-WinPlaybook

Atualiza o módulo WinPlaybook pela PowerShell Gallery e roda o
`Install-WinPlaybook` da versão nova, que atualiza o Ansible e os comandos.

## Sintaxe

```powershell
Update-WinPlaybook [-WhatIf] [-Confirm]
```

---

## Parâmetros

### -WhatIf

Mostra o que o comando faria, sem alterar nada.

---

## Exemplos

```powershell
Update-WinPlaybook
```

---

## Observações

- A versão do Ansible e os pacotes Python escolhidos no `Install-WinPlaybook`
  continuam os mesmos.
- Um módulo instalado pelo código-fonte não atualiza por este comando. Veja
  [Atualizar o WinPlaybook](update.md#instalacao-pelo-codigo-fonte).
