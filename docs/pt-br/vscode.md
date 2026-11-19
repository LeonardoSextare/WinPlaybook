# Usar o VS Code

Com a extensão Ansible da Red Hat, o VS Code mostra a documentação dos
módulos, completa os playbooks e os valida com o `ansible-lint`. Esta página
mostra como deixar a extensão funcionando com o WinPlaybook.

## Instalar a versão testada

O WinPlaybook corrige a extensão para ela funcionar no Windows, e cada versão
da extensão precisa ser testada antes. A versão testada é a 26.11.0:

```powershell
code --install-extension redhat.ansible@26.11.0
```

---

## Desligar a atualização automática da extensão

Uma atualização da extensão desfaz as correções. Na aba **Extensões** do VS
Code, clique com o botão direito na extensão **Ansible** e desmarque
**Atualização Automática** (_Auto Update_).

---

## Aplicar as correções

!!! tip "Na instalação"

    Com a extensão já instalada, o `Install-WinPlaybook` pergunta se você quer
    aplicar as correções. Nesse caso, este passo já está feito.

No PowerShell:

```powershell
Enable-WinPlaybookVSCodeExtension
```

O comando mostra a versão corrigida e a configuração que o VS Code precisa ter.

---

## Liberar a pasta da distribuição

A documentação dos módulos fica na distribuição do WinPlaybook, que o VS Code
abre pelo `\wsl.localhost`. Abra o `settings.json` do usuário (**Preferences:
Open User Settings (JSON)**) e acrescente:

```json
"security.allowedUNCHosts": ["wsl.localhost"]
```

Depois, recarregue a janela (**Developer: Reload Window**).

---

## Desfazer as correções

```powershell
Disable-WinPlaybookVSCodeExtension
```

O `Uninstall-WinPlaybook` também desfaz as correções.
