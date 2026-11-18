# Enable-WinPlaybookVSCodeExtension

Corrige a extensão Ansible do VS Code (`redhat.ansible`) para ela funcionar no
Windows com o WinPlaybook. As correções vão para a versão mais nova da
extensão instalada, desde que o WinPlaybook já tenha testado essa versão.

## Sintaxe

```powershell
Enable-WinPlaybookVSCodeExtension [-WhatIf] [-Confirm]
```

---

## Saída

Um objeto com:

| Propriedade        | Conteúdo                                                 |
| ------------------ | -------------------------------------------------------- |
| `Version`          | A versão corrigida da extensão                           |
| `Path`             | A pasta da extensão                                      |
| `RequiredSettings` | O que o `settings.json` do VS Code precisa ter           |

---

## Exemplos

```powershell
Enable-WinPlaybookVSCodeExtension
```

---

## O que altera

Os arquivos da extensão, em `C:\Users\<usuário>\.vscode\extensions`. Os
originais ficam guardados ao lado, com a extensão `.winplaybook-original`. O
comando não altera as configurações do VS Code.

Veja [Usar o VS Code](vscode.md) e
[Disable-WinPlaybookVSCodeExtension](disable-winplaybookvscodeextension.md).
