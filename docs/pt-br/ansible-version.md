# Escolher a versão do Ansible

O `Install-WinPlaybook` instala a versão mais nova do Ansible. Esta página
mostra como trocar a versão e instalar pacotes Python junto. Para fixar a
versão de um projeto só, veja [Usar um ambiente por projeto](project-environment.md).

## Trocar a versão

```powershell
Install-WinPlaybook -AnsibleVersion '12.*'
```

Para voltar à versão mais nova:

```powershell
Install-WinPlaybook -AnsibleVersion ''
```

---

## Instalar pacotes Python

Algumas _collections_ pedem pacotes Python, como o `boto3` para a AWS:

```powershell
Install-WinPlaybook -PythonPackage 'boto3', 'netaddr'
```

Uma ferramenta instalada assim, como o `molecule` ou o `yamllint`, ganha um
comando no Windows, como os do Ansible:

```powershell
Install-WinPlaybook -PythonPackage 'molecule', 'yamllint'
yamllint .
```

Para tirar os pacotes:

```powershell
Install-WinPlaybook -PythonPackage @()
```

As próximas execuções do `Install-WinPlaybook`, inclusive as do
`Update-WinPlaybook`, mantêm a versão e os pacotes escolhidos.
