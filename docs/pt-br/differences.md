# Diferenças em relação ao Ansible no Linux

O Ansible do WinPlaybook é o Ansible oficial, e a
[documentação do Ansible](https://docs.ansible.com/) vale para ele. Esta
página lista só o que muda porque ele é executado a partir do Windows.

## Hosts

| Host                | O que é                                                                  |
| ------------------- | ------------------------------------------------------------------------ |
| `localhost`         | O nó de controle: o Linux em que o Ansible roda, como no Ansible normal   |
| `localhost_windows` | A sua máquina Windows, quando [ligado](localhost-windows.md)             |

Os dois estão disponíveis mesmo sem constar no inventário e não fazem parte do
grupo `all`.

---

## Caminhos

- Os caminhos do Windows funcionam nos argumentos, nos arquivos do Ansible,
  como _playbooks_, inventários e o `ansible.cfg`, e nas variáveis de
  ambiente. Veja [Caminhos entre o Windows e o Linux](paths.md).
- Na saída, os caminhos aparecem no formato do Windows: `C:\infra\site.yml`.
- Dentro das tarefas que rodam no `localhost`, como no `{{ playbook_dir }}`,
  os caminhos estão no formato do Linux: `/mnt/c/infra`.

---

## Pastas do usuário

| Item                         | No Linux                  | No WinPlaybook                             |
| ---------------------------- | ------------------------- | ------------------------------------------ |
| _Collections_                | `~/.ansible/collections`  | `C:\Users\<usuário>\.ansible\collections`  |
| _Roles_                      | `~/.ansible/roles`        | `C:\Users\<usuário>\.ansible\roles`        |
| _Plugins_                    | `~/.ansible/plugins`      | `C:\Users\<usuário>\.ansible\plugins`      |
| Configuração do usuário      | `~/.ansible.cfg`          | `C:\Users\<usuário>\.ansible.cfg`          |
| Chaves e configuração do ssh | `~/.ssh`                  | `C:\Users\<usuário>\.ssh`                  |

O usuário padrão do `ssh` é o seu nome de usuário do Windows.

---

## Programas e scripts

- Os programas do `Path` do Windows funcionam nas tarefas do `localhost`.
  Quando um nome existe nos dois sistemas, como o `git`, vale o programa do
  Linux.
- Os _scripts_ do projeto são executados de acordo com a extensão: o `.ps1`
  pelo PowerShell e o `.bat` pelo `cmd.exe`, sem precisar da permissão de
  execução do Linux.
- O `ansible-vault edit` abre o editor do Windows.

Veja [Chamar programas e scripts do Windows](windows-programs.md).

---

## Rede

Nas tarefas, o `localhost` também alcança os serviços que estão rodando no
`localhost` do Windows, enquanto o comando é executado.

As conexões aos servidores saem pelo Windows, com as rotas e a VPN dele. Uma
conexão recusada pelo servidor aparece como interrompida
(`Connection reset by peer`). Veja [Rede](network.md).

---

## Tempo

Cada comando demora alguns segundos a mais para começar do que no Linux. O
acesso aos arquivos nas pastas do Windows também é mais lento do que num disco
do Linux, o que pesa em projetos com muitos arquivos.
