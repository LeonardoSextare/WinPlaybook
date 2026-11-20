# Recursos do WinPlaybook

O WinPlaybook faz o Ansible enxergar o seu Windows. Cada recurso abaixo tira
uma diferença entre rodar o Ansible no Windows e rodar no Linux.

<div class="grid cards" markdown>

-   :lucide-terminal: **Comandos no Windows**

    ---

    O `ansible-playbook`, o `ansible-galaxy`, o `ansible-lint` e os outros
    comandos ficam no `PATH`. O terminal, os _scripts_ e qualquer programa
    chamam esses comandos como chamam qualquer outro.

-   :lucide-folder-tree: **Caminhos do Windows**

    ---

    `.\playbooks\site.yml` e `C:\infra\hosts.yml` funcionam nos argumentos,
    nos _playbooks_, nos inventários e no `ansible.cfg`.

    [:lucide-arrow-right: Caminhos entre o Windows e o Linux](paths.md)

-   :lucide-key-round: **As suas chaves SSH**

    ---

    A pasta `.ssh` e o agente SSH do Windows, com as chaves, o `known_hosts`
    e o `config` que você já tem.

    [:lucide-arrow-right: Conectar em servidores por SSH](ssh.md)

-   :lucide-git-branch: **O seu login do Git**

    ---

    O `ansible-galaxy` e o módulo `git` usam o Git Credential Manager e
    alcançam os repositórios privados que você já acessa.

    [:lucide-arrow-right: Usar repositórios Git privados](git.md)

-   :lucide-shield-check: **Os certificados da empresa**

    ---

    O Ansible confia nos certificados raiz do Windows. Numa rede que
    inspeciona o tráfego, os downloads funcionam como no Windows.

    [:lucide-arrow-right: Credenciais](credentials.md#certificados)

-   :lucide-app-window: **Programas e scripts do Windows**

    ---

    As tarefas chamam os programas do `Path`, e os `.ps1` e `.bat` do projeto
    rodam como no Windows.

    [:lucide-arrow-right: Chamar programas e scripts do Windows](windows-programs.md)

-   :lucide-network: **A rede do Windows**

    ---

    As conexões saem pelo Windows, com a VPN, as rotas e as máquinas virtuais
    do Hyper-V dele, e um serviço no `localhost` do Windows, como um container
    do Docker Desktop, responde no `localhost` das tarefas.

    [:lucide-arrow-right: Rede](network.md)

-   :lucide-monitor-cog: **A sua máquina como host**

    ---

    Com o `localhost_windows`, os _playbooks_ configuram o próprio Windows,
    com os módulos `ansible.windows`.

    [:lucide-arrow-right: Configurar o próprio Windows](localhost-windows.md)

-   :lucide-package: **Um ambiente por projeto**

    ---

    Cada projeto fixa a versão do Ansible e dos pacotes Python num
    `pyproject.toml`.

    [:lucide-arrow-right: Usar um ambiente por projeto](project-environment.md)

-   :lucide-code: **VS Code**

    ---

    A extensão Ansible completa, documenta e valida os _playbooks_.

    [:lucide-arrow-right: Usar o VS Code](vscode.md)

-   :lucide-keyboard: **Autocomplete**

    ---

    A tecla ++tab++ completa as opções dos comandos do Ansible no PowerShell.

    [:lucide-arrow-right: Usar o autocomplete](autocomplete.md)

-   :lucide-bell-ring: **Avisos e logs**

    ---

    Aviso de versão nova e um log de cada comando, com o tempo de cada etapa.

    [:lucide-arrow-right: Consultar os logs](logs.md)

</div>
