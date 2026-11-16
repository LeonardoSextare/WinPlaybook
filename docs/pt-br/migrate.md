# Migrar da versão com Docker

Até a versão 0.2, o WinPlaybook rodava o Ansible num _container_ do Docker
Desktop. Veja como passar para a versão com o WSL, que tem outros comandos e
guarda as _collections_ em outro lugar. Antes de começar, confira os
[requisitos](install.md#requisitos).

## Atualizar o módulo

Atualize o módulo com o comando da sua versão do PowerShell:

- PowerShell 7.4 em diante: `Update-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Update-Module WinPlaybook`

Se você instalou pelo código-fonte, apague a pasta
`C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook`, instale o
módulo como em [Código-fonte](install.md#codigo-fonte) e apague a variável
que apontava para a imagem local:

```powershell
[Environment]::SetEnvironmentVariable('WINPLAYBOOK_IMAGE', $null, 'User')
```

## Instalar o Ansible

O `Install-WinPlaybook` substitui o `Install-WinPlaybookShim`. Ele cria a
distribuição WSL, instala o Ansible e troca os comandos antigos pelos novos:

```powershell
Install-WinPlaybook
```

Se você escolheu a pasta dos comandos com o `-Path` na versão anterior,
passe o mesmo `-Path` de novo. Sem ele, os comandos vão para a pasta padrão,
e a pasta antiga é apagada.

Para desinstalar, o `Uninstall-WinPlaybook` substitui o
`Uninstall-WinPlaybookShim`.

## Instalar de novo as collections e as roles

A versão com Docker guardava as _collections_ e as _roles_ em
`C:\Users\<usuário>\.ansible`. A versão com o WSL guarda dentro da
distribuição, então instale de novo as que você usa, por exemplo:

```powershell
ansible-galaxy collection install -r requirements.yml
```

Depois, se nenhum outro programa usa a pasta `C:\Users\<usuário>\.ansible`,
você pode apagá-la.

## Copiar o .ansible.cfg do usuário

A versão com Docker lia o `C:\Users\<usuário>\.ansible.cfg`. A versão com o
WSL lê o `.ansible.cfg` do usuário da distribuição. Se você tem esse arquivo,
copie-o para a distribuição:

```powershell
Invoke-WinPlaybook cp "$HOME\.ansible.cfg" /home/winplaybook/.ansible.cfg
```

O `ansible.cfg` dos projetos continua funcionando sem mudança.

## Remover o Docker

O WinPlaybook não usa mais o Docker Desktop. Apague a imagem antiga:

```powershell
docker image rm ghcr.io/leonardosextare/winplaybook:0
```

Se você instalou pelo código-fonte, apague também a imagem local com
`docker image rm winplaybook:local`. Se você não usa o Docker Desktop para
mais nada, pode desinstalá-lo.
