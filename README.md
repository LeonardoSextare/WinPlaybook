# WinPlaybook

Use o Ansible no Windows como se ele estivesse instalado localmente.

O WinPlaybook executa as ferramentas de linha de comando do Ansible numa
distribuição WSL e coloca o `ansible-playbook`, o `ansible-lint` e os outros
comandos do Ansible no `PATH` do Windows, onde o terminal e ferramentas como a
extensão Ansible do VS Code podem usá-los.

> **Status:** em desenvolvimento inicial. O projeto está na versão 0, então
> qualquer release pode trazer breaking changes.

## Requisitos

- Windows 10 ou 11
- Windows PowerShell 5.1 ou PowerShell 7.4 em diante
- WSL, com uma distribuição que tenha o Ansible instalado

## Licença

[MIT](LICENSE)
