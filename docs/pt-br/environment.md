# Ambiente

O Ansible roda no Linux, mas com o ambiente do Windows: as variáveis de
ambiente, os programas do `Path` e, num projeto com `pyproject.toml`, as
versões que o projeto declara.

## Variáveis de ambiente

O Ansible recebe as variáveis do terminal, com os caminhos já convertidos. As
variáveis que o Linux define por conta própria, como o `PATH` e o `HOME`, não
são repassadas. A lista está em [Variáveis de ambiente](environment-variables.md).

---

## Programas do Windows

O `PATH` das tarefas tem primeiro os programas da distribuição e, depois, os
programas do `Path` do Windows. Um programa do Windows roda pelo nome, com ou sem a
extensão, na ordem do `Path` e do `PATHEXT`, como no Windows.

Algumas exceções evitam confusão:

- quando um nome existe nos dois sistemas, como o `git` e o `ssh`, vale o
  programa do Linux, que é o que o Ansible espera;
- o Python e o pip do Windows só rodam com a extensão (`python.exe`), para o
  Ansible não escolher o Python do Windows para os módulos;
- os comandos do próprio WinPlaybook ficam de fora.

Os argumentos que são caminhos do Linux, como o `{{ playbook_dir }}`, chegam
ao programa do Windows como caminhos do Windows.

---

## Scripts do projeto

Um _script_ do projeto é executado de acordo com a extensão, como no Windows, sem precisar da
permissão de execução do Linux: o `.ps1` pelo `powershell.exe`, o `.bat` e o
`.cmd` pelo `cmd.exe`, o `.exe` direto, e o `.py` e o `.sh` pelo _shebang_. Por
isso, um inventário dinâmico ou um arquivo de senha do vault em `.ps1` funciona
como no Windows.

---

## Ambientes por projeto

Sem um `pyproject.toml`, os comandos usam o Ansible que o `Install-WinPlaybook`
instalou. Numa pasta com um `pyproject.toml` que declara o `ansible` ou o
`ansible-core`, eles usam um ambiente só daquele projeto, como o `uv run`
faria.

O ambiente fica no disco da distribuição, e não na pasta do projeto, que não
ganha uma `.venv`. Veja [Usar um ambiente por projeto](project-environment.md).
