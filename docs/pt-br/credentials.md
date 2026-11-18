# Credenciais

O WinPlaybook não guarda credenciais. Ele faz o Ansible usar as credenciais que
você já tem no Windows: as chaves SSH, o login do Git e os certificados.

## SSH

A pasta `.ssh` do Windows, em `C:\Users\<usuário>\.ssh`, é a `~/.ssh` da
distribuição. O `ssh` do Ansible usa as mesmas chaves, o mesmo `known_hosts` e
o mesmo `config`, sem cópias. Dentro da distribuição, a pasta aparece com as
permissões que o `ssh` exige, sem mudar as permissões dos arquivos no
Windows.

- Os hosts novos são gravados no `known_hosts` sem _hash_, como faz o `ssh`
  do Windows, e o arquivo fica num formato só. Para gravar com _hash_ nos dois
  sistemas, use `HashKnownHosts yes` no `config`.
- Sem um usuário no inventário ou no `config`, a conexão usa o seu nome de
  usuário do Windows.
- O `config` pode ter caminhos do Windows. O `ssh` usa uma cópia convertida
  dele, refeita a cada comando, e o arquivo do Windows fica como está.

### O agente SSH

Quando o agente SSH do Windows está ligado, o `ssh` do Ansible usa as chaves
que estão nele, e uma chave com passphrase funciona sem pedir a passphrase. Como o
Linux não acessa o agente do Windows diretamente, o WinPlaybook abre uma
conexão entre os dois a cada comando e a fecha quando o comando termina.

---

## Git

O Git da distribuição usa o seu `.gitconfig` do Windows, com o mesmo usuário e
os mesmos atalhos. O login passa pelo Git Credential Manager do Windows, então
o `ansible-galaxy` e o módulo `git` alcançam os repositórios privados que você
já acessa, sem um login novo.

---

## Certificados

O Ansible confia nos certificados raiz do Windows, além dos certificados do
Debian. Numa
rede que inspeciona o TLS, ou com uma autoridade certificadora interna
instalada no Windows, o `ansible-galaxy`, os módulos `uri` e `get_url`, o `git`
e o `pip` funcionam como no Windows.

---

## localhost_windows

A chave que o `localhost_windows` usa fica no disco da distribuição, e não na
sua pasta `.ssh`. O serviço `WinPlaybookSshd` só aceita essa chave, sem
senha, e só para o seu usuário.
