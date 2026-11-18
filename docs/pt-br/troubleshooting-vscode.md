# Problemas no VS Code

## A extensão não foi encontrada

!!! failure "Mensagem de erro"

    ```text
    A extensão Ansible do VS Code (redhat.ansible) não foi encontrada ...
    ```

Instale a versão testada, como em [Usar o VS Code](vscode.md#instalar-a-versao-testada),
e rode o `Enable-WinPlaybookVSCodeExtension` de novo.

---

## A versão da extensão não foi testada

!!! failure "Mensagem de erro"

    ```text
    A extensão Ansible do VS Code está na versão ..., que o WinPlaybook ainda não testou.
    ```

A extensão foi atualizada. Volte para a versão testada e desligue a
atualização automática, como em [Usar o VS Code](vscode.md).

---

## As correções pararam de funcionar

Uma atualização da extensão desfaz as correções. Confira a versão instalada na
aba **Extensões**, volte para a versão testada se for preciso e rode:

```powershell
Enable-WinPlaybookVSCodeExtension
```

---

## A extensão não acha o Ansible

Feche todas as janelas do VS Code e abra de novo. Um VS Code aberto antes da
instalação não enxerga os comandos do Ansible.

---

## A documentação dos módulos não aparece

O VS Code bloqueia os arquivos do `\\wsl.localhost` sem a configuração
`security.allowedUNCHosts`. Veja
[Liberar a pasta da distribuição](vscode.md#liberar-a-pasta-da-distribuicao).

---

## A correção não foi aplicada

!!! failure "Mensagem de erro"

    ```text
    Não foi possível corrigir a extensão Ansible do VS Code em ...: o arquivo ... não tem o trecho esperado da versão ...
    ```

Os arquivos da extensão mudaram. Reinstale a versão testada com o comando da
mensagem, que termina com `--force`, e rode o
`Enable-WinPlaybookVSCodeExtension` de novo.
