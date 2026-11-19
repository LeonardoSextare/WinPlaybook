# Desinstalar o WinPlaybook

Apague a distribuição e os comandos do Ansible:

```powershell
Uninstall-WinPlaybook
```

!!! warning "Atenção"

    O comando pede confirmação, porque a distribuição é apagada com tudo o que há
    nela. O padrão é não: o Enter cancela, sem mudar nada. Se o `localhost_windows` está ligado, o Windows também pede a aprovação
    de administrador para desligá-lo.

Depois, remova o módulo:

=== "PowerShell 7.4 em diante"

    ```powershell
    Uninstall-PSResource WinPlaybook
    ```

=== "Windows PowerShell 5.1"

    ```powershell
    Uninstall-Module WinPlaybook
    ```

Se você instalou pelo código-fonte, apague a pasta
`C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook`.

## O que fica

O WinPlaybook não apaga o que é seu:

- as _collections_ e as _roles_ em `C:\Users\<usuário>\.ansible`;
- a pasta `.ssh`, quando ela tem arquivos;
- os seus projetos.

A lista completa do que o WinPlaybook cria e apaga está em
[O que o WinPlaybook altera no sistema](system-changes.md).
