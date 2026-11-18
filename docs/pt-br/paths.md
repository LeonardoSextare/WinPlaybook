# Caminhos entre o Windows e o Linux

O Linux não entende `C:\infra`. A distribuição enxerga as unidades do Windows
em pastas próprias, como `/mnt/c`, e o WinPlaybook converte os caminhos nos dois
sentidos. Cada caminho continua apontando para o mesmo arquivo.

## Do Windows para o Linux

Antes de rodar o comando, o WinPlaybook converte os argumentos que são
caminhos do Windows e deixa os outros como estão:

- um caminho com a letra da unidade passa a apontar para a pasta da unidade
  em `/mnt`;
- um caminho numa unidade criada com o `subst` passa a apontar para a pasta
  real;
- um caminho de rede, ou numa unidade de rede mapeada, passa a apontar para
  `/mnt/unc/<servidor>/<compartilhamento>`, que a distribuição monta com as
  suas credenciais do Windows;
- um caminho do disco da distribuição, em `\\wsl.localhost\WinPlaybook\`,
  é convertido para o caminho correspondente no Linux;
- num caminho relativo, as `\` viram `/` quando ele começa com `.\` ou
  `..\`, ou quando a pasta existe, mesmo que o arquivo ainda não exista.

A conversão também vale depois de uma opção com `=` ou de um `@`, e no valor
de um `chave=valor`, como os do `-e` e do `-a` (`-e pasta=C:\infra\files`).

Com a pasta atual em `C:\infra`, que tem as pastas `vars` e `saida`:

| Argumento                                            | Na distribuição                      |
| ---------------------------------------------------- | ------------------------------------ |
| `.\playbooks\site.yml`                               | `./playbooks/site.yml`               |
| `C:\infra\inventory\prod.yml`                        | `/mnt/c/infra/inventory/prod.yml`    |
| `D:\outros\hosts.yml`                                | `/mnt/d/outros/hosts.yml`            |
| `\\servidor\infra\site.yml`                          | `/mnt/unc/servidor/infra/site.yml`   |
| `--inventory=C:\infra\hosts.yml`                     | `--inventory=/mnt/c/infra/hosts.yml` |
| `@vars\prod.yml`                                     | `@vars/prod.yml`                     |
| `saida\relatorio.json`, que ainda não existe         | `saida/relatorio.json`               |
| `\\wsl.localhost\WinPlaybook\home\winplaybook\a.yml` | `/home/winplaybook/a.yml`            |
| `~web\d+`                                            | `~web\d+`, não é caminho             |

---

## Dentro dos arquivos do Ansible

Um caminho absoluto do Windows também funciona dentro dos arquivos: numa
variável (`arquivo: C:\infra\files\dado.txt`), no `src` de um `copy` ou
`template`, num _lookup_ ou `include`, no inventário e nos caminhos do
`ansible.cfg`, como o `roles_path`, que pode separar vários caminhos do Windows
por `;`.

---

## Nas variáveis de ambiente

Os caminhos nas variáveis de ambiente seguem as mesmas regras. Veja
[Variáveis de ambiente](environment-variables.md).

---

## Do Linux para o Windows

Na saída dos comandos, os caminhos das unidades do Windows aparecem no formato
do Windows, com barras normais: um erro aponta para `C:/infra/site.yml`, e não
para `/mnt/c/infra/site.yml`. Com as barras normais, uma saída em JSON
continua válida, e o Windows e o VS Code conseguem abrir esses caminhos.

---

## Finais de linha

Um _script_ com _shebang_ (`#!/bin/sh`) e finais de linha CRLF, como os que o
Git for Windows grava por padrão, funciona no `ansible.builtin.script`: o
Ansible envia uma cópia sem os CR, e o arquivo do projeto fica como está.
