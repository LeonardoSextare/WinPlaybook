# Usar repositórios Git privados

O Ansible usa o seu Git do Windows: o mesmo `.gitconfig`, o mesmo usuário e o
mesmo login. Se você já clona um repositório privado no Windows, o
`ansible-galaxy` e o módulo `ansible.builtin.git` também clonam.

## Requisitos

| Requisito                                              | Versão          |
| ------------------------------------------------------ | --------------- |
| [Git for Windows](https://git-scm.com/download/win)    | Mais recente    |

O Git for Windows já vem com o Git Credential Manager, que guarda o seu login.

---

## Fazer o login

Clone qualquer repositório privado no Windows uma vez. O Git Credential Manager
abre o navegador para o login e guarda a credencial:

```powershell
git clone https://github.com/minha-empresa/infra-collection.git
```

Depois disso, o Ansible usa a mesma credencial, sem pedir nada.

---

## Usar no Ansible

Numa tarefa que roda no `localhost`:

```yaml
- name: Baixa o código da aplicação para a pasta do projeto
  ansible.builtin.git:
    repo: https://github.com/minha-empresa/app.git
    dest: '{{ playbook_dir }}/app'
  delegate_to: localhost
```

!!! note "Só na sua máquina"

    O login vale só na sua máquina. Um servidor que clona o repositório precisa
    de uma credencial própria, como no Linux.

Num `requirements.yml`, veja [Instalar collections e roles](collections-and-roles.md#instalar-de-um-repositorio-git-privado).

---

## Repositórios por SSH

Um repositório com endereço `git@...` usa as chaves da sua pasta `.ssh`. Veja
[Conectar em servidores por SSH](ssh.md).
