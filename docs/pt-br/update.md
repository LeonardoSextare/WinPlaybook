# Atualizar o WinPlaybook

Atualize o módulo, o Ansible e os comandos de uma vez:

```powershell
Update-WinPlaybook
```

A versão do Ansible e os pacotes Python que você escolheu continuam os
mesmos.

## O aviso de versão nova

O WinPlaybook avisa quando existe uma versão nova, na primeira vez que você
roda um comando dele no terminal:

```text
WinPlaybook: a versão 0.20.0 está disponível (você usa a 0.19.0). Atualize com: Update-WinPlaybook
```

Para desligar o aviso, defina a variável de ambiente
`WINPLAYBOOK_UPDATE_CHECK` como `off`:

```powershell
[Environment]::SetEnvironmentVariable('WINPLAYBOOK_UPDATE_CHECK', 'off', 'User')
```

---

## Instalação pelo código-fonte

!!! note "Código-fonte"

    Se você instalou pelo código-fonte, apague a pasta
    `C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook`, repita os
    passos 1 e 2 da [instalação](install.md#codigo-fonte) com o código novo e rode
    o `Install-WinPlaybook`.
