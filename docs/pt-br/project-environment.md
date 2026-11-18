# Usar um ambiente por projeto

Um projeto pode fixar a própria versão do Ansible e dos pacotes Python com um
`pyproject.toml` do [uv](https://docs.astral.sh/uv/). Assim, cada projeto usa
as versões que ele declara, sem afetar os outros.

## Declarar o ambiente

Crie um `pyproject.toml` na raiz do projeto, com o `ansible` ou o
`ansible-core` nas dependências:

```toml
[project]
name = "infra"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["ansible-core==2.19.*", "ansible-lint", "boto3"]
```

!!! success "Como o uv run"

    Na pasta do projeto, ou numa subpasta, os comandos do Ansible passam a usar
    esse ambiente, como o `uv run` faria. Na primeira vez, o WinPlaybook instala os
    pacotes, e o uv grava o `uv.lock` no projeto. Faça o _commit_ dos dois
    arquivos.

---

## O que muda dentro do projeto

- Só funcionam os comandos que o projeto declara. Uma ferramenta que você
  instalou com o `Install-WinPlaybook -PythonPackage`, como o `molecule`, não
  funciona num projeto que não a declara.
- Uma ferramenta que o projeto declara, como o `yamllint`, ganha um comando no
  Windows depois do primeiro comando do WinPlaybook na pasta do projeto.
- O ambiente fica no disco da distribuição. A pasta do projeto não ganha uma
  `.venv`.
- Para o [autocomplete](autocomplete.md) funcionar, acrescente o pacote
  `argcomplete` às dependências.
