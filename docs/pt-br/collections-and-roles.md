# Instalar collections e roles

O `ansible-galaxy` funciona como no Linux. A diferença é onde as _collections_
e as _roles_ ficam: no seu perfil do Windows, como num Ansible instalado no
Windows.

| Tipo          | Onde fica                                    |
| ------------- | -------------------------------------------- |
| _Collections_ | `C:\Users\<usuário>\.ansible\collections`    |
| _Roles_       | `C:\Users\<usuário>\.ansible\roles`          |

## Instalar uma collection

```powershell
ansible-galaxy collection install community.general
```

---

## Instalar as dependências de um projeto

Liste as _collections_ e as _roles_ num `requirements.yml`:

```yaml
collections:
  - name: community.general
  - name: ansible.posix
roles:
  - name: geerlingguy.docker
```

E instale:

```powershell
ansible-galaxy install -r requirements.yml
```

---

## Instalar de um repositório Git privado

!!! tip "Repositórios privados"

    O `ansible-galaxy` usa o seu login do Git no Windows. Se você já clona o
    repositório no Windows, ele funciona aqui também:

```yaml
collections:
  - name: https://github.com/minha-empresa/infra-collection.git
    type: git
    version: main
```

Veja [Usar repositórios Git privados](git.md).

---

## Usar uma pasta do projeto

Para guardar as _collections_ junto com o projeto, defina a pasta no
`ansible.cfg` dele. Caminhos relativos e caminhos do Windows funcionam:

```ini
[defaults]
collections_path = ./collections
roles_path = ./roles;C:\roles-compartilhadas
```
