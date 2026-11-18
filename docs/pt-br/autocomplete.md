# Usar o autocomplete

No PowerShell, a tecla Tab completa as opções dos comandos do Ansible, como
`ansible-playbook --che` para `--check`, e os subcomandos, como
`ansible-galaxy co` para `collection`. Os caminhos continuam sendo completados
como em qualquer comando.

O `Install-WinPlaybook` liga o autocomplete nos perfis do PowerShell 7 e do
Windows PowerShell. Ele funciona em todo terminal novo, sem configuração.

## Num projeto com ambiente próprio

Num projeto com [ambiente próprio](project-environment.md), acrescente o
pacote `argcomplete` às dependências do `pyproject.toml`:

```toml
dependencies = ["ansible-core==2.19.*", "argcomplete"]
```

---

## Num terminal que já estava aberto

Num terminal aberto antes da instalação, ligue o autocomplete na hora:

```powershell
Register-WinPlaybookArgumentCompleter
```
