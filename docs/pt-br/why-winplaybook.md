# Por que o WinPlaybook

O Ansible [não tem suporte ao Windows como máquina de controle](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html#control-node-requirements),
a máquina de onde os *playbooks* são executados. Só que quem trabalha no
Windows já tem um ambiente montado: o PowerShell com os módulos e o perfil
configurados, o editor com as extensões que usa, os atalhos e os scripts do
dia a dia. Usar o Ansible significa sair desse ambiente.

## As alternativas comuns

As formas comuns de usar o Ansible no Windows são o WSL, uma máquina virtual
ou um servidor Linux, muitas vezes acessados pelas extensões
[WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)
e
[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
do VS Code. Todas funcionam: o Ansible roda, e os *playbooks* também.

O custo é o mesmo em todas: o Ansible fica em outro sistema, e você passa a
trabalhar nele. O que você deixou configurado no Windows não vai junto. Você
monta o ambiente de novo do outro lado e se acostuma com outro terminal, outro
*shell* e outro jeito de trabalhar. Nem as extensões do VS Code evitam isso: a
janela do editor fica no Windows, mas o terminal, os arquivos e parte das
extensões rodam no Linux, e essas extensões precisam ser instaladas de novo.

---

## Por que uma distribuição WSL própria

O WinPlaybook coloca os comandos do Ansible no `PATH` do Windows e roda cada
um numa distribuição WSL que é só dele. O `ansible-playbook` fica acessível
para o terminal e para qualquer programa que roda no Windows, como um comando
nativo, e você continua trabalhando no Windows. A distribuição fica por trás
dos comandos, e você não precisa abrir um terminal nela.

O WSL é um recurso do próprio Windows e enxerga as unidades dele. O Ansible lê os
_playbooks_ na pasta onde eles já estão, e o WinPlaybook converte os caminhos
do Windows nos argumentos para os caminhos da distribuição. Você não instala o
Python nem o Ansible no Windows.

A distribuição é própria para não mexer nas distribuições que você já tem. O WinPlaybook a
configura como o Ansible precisa, e o `Uninstall-WinPlaybook` a apaga por
inteiro.

Em troca, a primeira instalação baixa o Debian e o Ansible e leva alguns
minutos, e cada comando leva um pouco mais para começar. Essas e outras
limitações estão em [Limitações conhecidas](limitations.md).
