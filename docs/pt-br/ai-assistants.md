# Usar com assistentes de IA

Os assistentes de IA, como o Claude Code, o GitHub Copilot e o Cursor, não
conhecem o WinPlaybook. Num projeto Ansible no Windows, eles costumam sugerir
instalar o Ansible no WSL, abrir um terminal Linux ou trocar os caminhos do
Windows por caminhos do Linux. Esta página mostra como explicar o WinPlaybook
para eles.

## Acrescentar as instruções ao projeto

Copie o bloco abaixo para o arquivo de instruções que o seu assistente lê, na
raiz do projeto:

| Assistente     | Arquivo                           |
| -------------- | --------------------------------- |
| Vários         | `AGENTS.md`                       |
| Claude Code    | `CLAUDE.md`                       |
| GitHub Copilot | `.github/copilot-instructions.md` |

!!! tip "Um arquivo para todos"

    Muitos assistentes leem o `AGENTS.md`. No Claude Code, um `CLAUDE.md` com a
    linha `@AGENTS.md` importa o mesmo conteúdo.

```markdown
## Ansible com o WinPlaybook

Este projeto usa o Ansible no Windows pelo WinPlaybook
(https://leonardosextare.github.io/WinPlaybook/).

- Os comandos do Ansible (`ansible-playbook`, `ansible-galaxy`, `ansible-lint`
  e os outros) rodam direto no PowerShell do Windows. Não sugira instalar o
  Ansible no WSL, abrir um terminal Linux nem usar `wsl` antes dos comandos.
- Caminhos do Windows funcionam nos argumentos, nos playbooks, nos inventários
  e no `ansible.cfg`, como `.\playbooks\site.yml` e `C:\infra\hosts.yml`.
- O `localhost` é o nó de controle, um Linux. A máquina Windows do usuário é o
  host `localhost_windows`, que usa os módulos `ansible.windows`.
- As collections e as roles ficam em `C:\Users\<usuário>\.ansible`. As chaves
  SSH ficam na pasta `.ssh` do Windows, e o agente SSH do Windows funciona.
- Programas do `Path` do Windows funcionam nas tarefas do `localhost`. Quando
  o nome existe nos dois sistemas, como o `git`, vale o do Linux.
- Para mudar a versão do Ansible num projeto, use um `pyproject.toml` do uv
  com o `ansible` ou o `ansible-core` nas dependências.
- As diferenças em relação ao Ansible no Linux estão em
  https://leonardosextare.github.io/WinPlaybook/pt-br/differences/
```

---

## Manter as instruções em dia

O bloco descreve o WinPlaybook desta versão. Depois de uma atualização com
mudanças grandes, confira esta página e copie o bloco de novo.
