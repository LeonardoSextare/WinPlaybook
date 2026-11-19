# Problemas no localhost_windows

## O host localhost_windows não existe

!!! failure "Mensagem de erro"

    ```text
    [WARNING]: Could not match supplied host pattern, ignoring: localhost_windows
    ```

O `localhost_windows` está desligado. Ligue com:

```powershell
Enable-WinPlaybookLocalhost
```

---

## O Windows não abriu o PowerShell de administrador

!!! failure "Mensagem de erro"

    ```text
    O Windows não abriu o PowerShell de administrador, que o comando precisa ...
    ```

A janela de aprovação foi recusada ou fechada. Rode o comando de novo e
aprove. Se a sua conta não é administradora, peça a quem administra a máquina
para rodar o comando por você.

---

## O comando falhou como administrador

!!! failure "Mensagem de erro"

    ```text
    O comando Enable-WinPlaybookLocalhost -Confirm:$false falhou como administrador (código de saída 1): ...
    ```

O fim da mensagem traz a causa. Corrija o que ela indica e rode o comando de
novo. Se a causa não estiver clara, [abra uma issue](report-issue.md) com a
mensagem completa.

---

## O OpenSSH não foi baixado

!!! failure "Mensagem de erro"

    ```text
    Não foi possível baixar o OpenSSH de https://github.com/PowerShell/Win32-OpenSSH/...
    ```

O WinPlaybook baixa o OpenSSH do GitHub. Confira se o Windows acessa a
internet e se a rede, ou o proxy da empresa, libera o `github.com`. Depois,
rode o `Enable-WinPlaybookLocalhost` de novo.

---

## O serviço WinPlaybookSshd não iniciou

!!! failure "Mensagem de erro"

    ```text
    O serviço WinPlaybookSshd não iniciou. ...
    ```

Rode o `Enable-WinPlaybookLocalhost` de novo. Se o erro continuar,
[abra uma issue](report-issue.md) com a mensagem completa.

---

## UNREACHABLE ao conectar

!!! failure "Mensagem de erro"

    ```text
    localhost_windows | UNREACHABLE! => ... Connection refused
    ```

Confira se o serviço está rodando:

```powershell
Get-Service WinPlaybookSshd
```

Se ele está parado, inicie num PowerShell como administrador:

```powershell
Start-Service WinPlaybookSshd
```
