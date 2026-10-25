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

## Por que um container

O WinPlaybook coloca os comandos do Ansible no `PATH` do Windows e roda cada
um num *container* descartável, que o Docker cria na hora e remove no fim. O
`ansible-playbook` fica acessível para o terminal e para qualquer programa que
roda no Windows, como um comando nativo, e você continua trabalhando no
Windows.

O [Docker Desktop](https://docs.docker.com/desktop/) já roda Linux sem
configuração extra. A imagem do WinPlaybook traz o Ansible, o `ansible-lint` e
as bibliotecas para gerenciar máquinas Windows. Você não instala o Python nem
o Ansible no Windows, e as versões das ferramentas são as mesmas para todos
que usam a mesma imagem.

Em troca, o Docker Desktop precisa estar em execução, e cada comando leva
alguns segundos a mais para começar. Essas e outras limitações estão em
[Como funciona](how-it-works.md#limitacoes).
