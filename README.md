# WinPlaybook

[![Módulo](https://github.com/LeonardoSextare/WinPlaybook/actions/workflows/module.yml/badge.svg?branch=main)](https://github.com/LeonardoSextare/WinPlaybook/actions/workflows/module.yml)
[![Documentação](https://github.com/LeonardoSextare/WinPlaybook/actions/workflows/docs.yml/badge.svg?branch=main)](https://github.com/LeonardoSextare/WinPlaybook/actions/workflows/docs.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/WinPlaybook?label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/WinPlaybook)
[![Downloads](https://img.shields.io/powershellgallery/dt/WinPlaybook?label=downloads)](https://www.powershellgallery.com/packages/WinPlaybook)
[![Licença](https://img.shields.io/github/license/LeonardoSextare/WinPlaybook?label=licen%C3%A7a)](LICENSE)

Use o Ansible no Windows como se ele estivesse instalado localmente.

O WinPlaybook executa o Ansible numa distribuição WSL própria e coloca o
`ansible-playbook`, o `ansible-lint` e os outros comandos do Ansible no `PATH`
do Windows. O terminal, os scripts e ferramentas como a extensão Ansible do
VS Code chamam esses comandos sem saber que eles rodam no Linux.

> **Status:** o projeto está na versão 0, então qualquer release pode trazer
> breaking changes. A versão da PowerShell Gallery ainda usa o Docker Desktop;
> a versão com o WSL, descrita aqui, sai no próximo release.

## Instalação

Você precisa do Windows 10 ou 11, do WSL 2 e do Windows PowerShell 5.1 ou do
PowerShell 7.4 em diante. No PowerShell, execute:

```powershell
Install-Module WinPlaybook -Scope CurrentUser
Install-WinPlaybook
```

Na primeira vez, o `Install-WinPlaybook` cria a distribuição WSL
`WinPlaybook`, com o Debian, e instala o Ansible nela. Depois, teste com
`ansible --version`.

As outras formas de instalação, como pelo código-fonte, estão na
[documentação](https://leonardosextare.github.io/WinPlaybook/pt-br/install/).

## Uso

Use os comandos do Ansible como no Linux, com caminhos do Windows:

```powershell
ansible-playbook -i .\inventory\prod.yml .\playbooks\site.yml
```

## Documentação

A [documentação](https://leonardosextare.github.io/WinPlaybook/), em
português e inglês, explica a instalação e o funcionamento do WinPlaybook.

## Licença

[MIT](LICENSE)
