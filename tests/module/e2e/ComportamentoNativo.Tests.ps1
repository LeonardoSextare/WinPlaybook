BeforeDiscovery {
    $cenarios = @(
        @{
            Descricao = 'o playbook termina sem erros'
            Projeto   = 'ola'
            Comando   = 'ansible-playbook'
            NoLinux   = @('site.yml')
            NoWindows = @('site.yml')
        }
        @{
            Descricao = 'uma tarefa do playbook falha'
            Projeto   = 'falha'
            Comando   = 'ansible-playbook'
            NoLinux   = @('site.yml')
            NoWindows = @('site.yml')
        }
        @{
            Descricao = 'o playbook não existe'
            Projeto   = 'ola'
            Comando   = 'ansible-playbook'
            NoLinux   = @('inexistente.yml')
            NoWindows = @('inexistente.yml')
        }
        @{
            Descricao = 'a saída tem acentos'
            Projeto   = 'acentos'
            Comando   = 'ansible-playbook'
            NoLinux   = @('site.yml')
            NoWindows = @('site.yml')
        }
        @{
            Descricao = 'o texto cifrado vem pela entrada padrão'
            Projeto   = 'senha-do-vault'
            Comando   = 'ansible-vault'
            NoLinux   = @('decrypt', '--vault-password-file', 'senha.txt')
            NoWindows = @('decrypt', '--vault-password-file', 'senha.txt')
            Entrada   = 'segredo.yml'
        }
        @{
            Descricao = 'o comando mostra a versão'
            Projeto   = 'ola'
            Comando   = 'ansible'
            NoLinux   = @('--version')
            NoWindows = @('--version')
        }
        @{
            Descricao = 'um argumento tem JSON com aspas e espaços'
            Projeto   = 'ola'
            Comando   = 'ansible'
            NoLinux   = @('localhost', '-m', 'ansible.builtin.debug', '-a', 'msg={{ saudacao }}', '-e', '{"saudacao": "oi mundo"}')
            NoWindows = @('localhost', '-m', 'ansible.builtin.debug', '-a', 'msg={{ saudacao }}', '-e', '{"saudacao": "oi mundo"}')
        }
        @{
            Descricao = 'um argumento tem caracteres especiais do shell e do Windows'
            Projeto   = 'ola'
            Comando   = 'ansible'
            NoLinux   = @('localhost', '-m', 'ansible.builtin.debug', '-a', '{"msg": "$HOME * ; | & `id` %PATH% ^ ! ''a''"}')
            NoWindows = @('localhost', '-m', 'ansible.builtin.debug', '-a', '{"msg": "$HOME * ; | & `id` %PATH% ^ ! ''a''"}')
        }
        @{
            Descricao = 'um argumento tem JSON com um caminho do Windows'
            Projeto   = 'ola'
            Comando   = 'ansible'
            NoLinux   = @('localhost', '-m', 'ansible.builtin.debug', '-a', 'msg={{ caminho }}', '-e', '{"caminho": "C:\\Temp"}')
            NoWindows = @('localhost', '-m', 'ansible.builtin.debug', '-a', 'msg={{ caminho }}', '-e', '{"caminho": "C:\\Temp"}')
        }
        @{
            Descricao = 'um argumento é vazio'
            Projeto   = 'ola'
            Comando   = 'ansible'
            NoLinux   = @('localhost', '-m', 'ansible.builtin.debug', '-a', '')
            NoWindows = @('localhost', '-m', 'ansible.builtin.debug', '-a', '')
        }
        @{
            Descricao = 'o playbook vem por um caminho relativo com barra invertida'
            Projeto   = 'ola'
            Comando   = 'ansible-playbook'
            NoLinux   = @('./site.yml')
            NoWindows = @('.\site.yml')
        }
        @{
            Descricao = 'o playbook vem por um caminho absoluto'
            Projeto   = 'ola'
            Comando   = 'ansible-playbook'
            NoLinux   = @('<projeto>/site.yml')
            NoWindows = @('<projeto>\site.yml')
        }
        @{
            Descricao      = 'o projeto está no disco do Linux'
            Projeto        = 'ola'
            Comando        = 'ansible-playbook'
            NoLinux        = @('site.yml')
            NoWindows      = @('site.yml')
            PastaDoProjeto = 'DiscoDoLinux'
        }
        @{
            Descricao      = 'o playbook vem por um caminho absoluto do disco do Linux'
            Projeto        = 'ola'
            Comando        = 'ansible-playbook'
            NoLinux        = @('<projeto>/site.yml')
            NoWindows      = @('<projeto>\site.yml')
            PastaDoProjeto = 'DiscoDoLinux'
        }
        @{
            Descricao = 'as variáveis extras vêm de um arquivo depois de @'
            Projeto   = 'inventario'
            Comando   = 'ansible-playbook'
            NoLinux   = @('-i', 'inventario.yml', '-e', '@vars/prod.yml', 'site.yml')
            NoWindows = @('-i', 'inventario.yml', '-e', '@vars\prod.yml', 'site.yml')
        }
        @{
            Descricao = 'o inventário vem por um caminho absoluto'
            Projeto   = 'inventario'
            Comando   = 'ansible-playbook'
            NoLinux   = @('-i', '<projeto>/inventario.yml', 'site.yml')
            NoWindows = @('-i', '<projeto>\inventario.yml', 'site.yml')
        }
        @{
            Descricao = 'o inventário vem por um caminho absoluto depois de uma opção com ='
            Projeto   = 'inventario'
            Comando   = 'ansible-playbook'
            NoLinux   = @('--inventory=<projeto>/inventario.yml', 'site.yml')
            NoWindows = @('--inventory=<projeto>\inventario.yml', 'site.yml')
        }
        @{
            Descricao = 'o padrão de hosts depois de uma opção com = tem dois-pontos'
            Projeto   = 'inventario'
            Comando   = 'ansible-playbook'
            NoLinux   = @('-i', 'inventario.yml', '--limit=servidores:web1', 'site.yml')
            NoWindows = @('-i', 'inventario.yml', '--limit=servidores:web1', 'site.yml')
        }
        @{
            Descricao = 'o inventário é listado em JSON'
            Projeto   = 'inventario'
            Comando   = 'ansible-inventory'
            NoLinux   = @('-i', 'inventario.yml', '--list')
            NoWindows = @('-i', 'inventario.yml', '--list')
        }
        @{
            Descricao = 'o arquivo de saída ainda não existe e começa com .\'
            Projeto   = 'arquivo-de-saida'
            Comando   = 'ansible-inventory'
            NoLinux   = @('-i', 'inventario.yml', '--list', '--output', './inventario.json')
            NoWindows = @('-i', 'inventario.yml', '--list', '--output', '.\inventario.json')
        }
        @{
            Descricao = 'o arquivo de saída ainda não existe numa pasta que existe'
            Projeto   = 'arquivo-de-saida'
            Comando   = 'ansible-inventory'
            NoLinux   = @('-i', 'inventario.yml', '--list', '--output', 'saida/inventario.json')
            NoWindows = @('-i', 'inventario.yml', '--list', '--output', 'saida\inventario.json')
        }
        @{
            Descricao = 'a pasta atual tem um ansible.cfg'
            Projeto   = 'configuracao-do-projeto'
            Comando   = 'ansible-playbook'
            NoLinux   = @('playbooks/site.yml')
            NoWindows = @('playbooks\site.yml')
        }
        @{
            Descricao = 'o ansible-config mostra a configuração da pasta atual'
            Projeto   = 'configuracao-do-projeto'
            Comando   = 'ansible-config'
            NoLinux   = @('dump', '--only-changed')
            NoWindows = @('dump', '--only-changed')
        }
        @{
            Descricao = 'a senha do vault vem de um arquivo do projeto'
            Projeto   = 'senha-do-vault'
            Comando   = 'ansible-playbook'
            NoLinux   = @('--vault-password-file', 'senha.txt', 'site.yml')
            NoWindows = @('--vault-password-file', 'senha.txt', 'site.yml')
        }
        @{
            Descricao        = 'uma variável ANSIBLE_ do Windows muda a configuração'
            Projeto          = 'ola'
            Comando          = 'ansible-playbook'
            NoLinux          = @('site.yml')
            NoWindows        = @('site.yml')
            VariaveisNoLinux = @{ ANSIBLE_DISPLAY_OK_HOSTS = 'false' }
            Variaveis        = @{ ANSIBLE_DISPLAY_OK_HOSTS = 'false' }
        }
        @{
            Descricao        = 'uma variável ANSIBLE_ do Windows aponta para um arquivo do projeto'
            Projeto          = 'configuracao-pela-variavel'
            Comando          = 'ansible-config'
            NoLinux          = @('dump', '--only-changed')
            NoWindows        = @('dump', '--only-changed')
            VariaveisNoLinux = @{ ANSIBLE_CONFIG = '<projeto>/config/ansible.cfg' }
            Variaveis        = @{ ANSIBLE_CONFIG = '<projeto>\config\ansible.cfg' }
        }
        @{
            Descricao        = 'o playbook lê uma variável que o usuário pôs no WSLENV'
            Projeto          = 'variavel-de-ambiente'
            Comando          = 'ansible-playbook'
            NoLinux          = @('site.yml')
            NoWindows        = @('site.yml')
            VariaveisNoLinux = @{ WINPLAYBOOK_TEST_MENSAGEM = 'oi do ambiente' }
            Variaveis        = @{ WINPLAYBOOK_TEST_MENSAGEM = 'oi do ambiente'; WSLENV = 'WINPLAYBOOK_TEST_MENSAGEM' }
        }
        @{
            Descricao = 'o ansible-doc mostra a documentação de um módulo'
            Projeto   = 'ola'
            Comando   = 'ansible-doc'
            NoLinux   = @('ansible.builtin.debug')
            NoWindows = @('ansible.builtin.debug')
        }
        @{
            Descricao = 'o ansible-galaxy cria uma role na pasta atual'
            Projeto   = 'ola'
            Comando   = 'ansible-galaxy'
            NoLinux   = @('role', 'init', 'minha_role')
            NoWindows = @('role', 'init', 'minha_role')
        }
    )
}

BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/AnsibleNativo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste

    $localAppDataOriginal = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'

    $pastaDosShims = Join-Path $TestDrive 'shims'
    $null = New-Item -ItemType Directory -Path $pastaDosShims
    $parametrosDosShims = @{ Pasta = $pastaDosShims; CaminhoDoPowerShell = (Get-Process -Id $PID).Path; Distribuicao = $nomeDaDistribuicao }
    InModuleScope WinPlaybook -Parameters $parametrosDosShims {
        $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao
        Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = $raizDeMontagem }
        foreach ($comando in Get-ComandoDoAnsible -Distribuicao $Distribuicao -RaizDeMontagem $raizDeMontagem) {
            New-ShimDeComando -Nome $comando -Pasta $Pasta -CaminhoDoPowerShell $CaminhoDoPowerShell -PastaDoModulo (Get-PastaDoModulo)
        }
    }

    $pastaDosProjetos = Join-Path $PSScriptRoot '../data/projects'

    function Invoke-CenarioNativo {
        <#
        .SYNOPSIS
        Executa o cenário direto no Linux da distribuição, a partir de uma cópia do projeto no disco do Linux.

        .DESCRIPTION
        Com Entrada, o comando recebe esse arquivo do projeto na entrada padrão, e com
        VariaveisNoLinux, essas variáveis de ambiente. Devolve um objeto com CodigoDeSaida, Saida,
        Erro e Arquivos, com a pasta do projeto trocada por <projeto>.

        .PARAMETER Cenario
        O cenário, com Projeto, Comando e os argumentos no formato do Linux (NoLinux).

        .EXAMPLE
        $nativo = Invoke-CenarioNativo -Cenario $cenario
        #>
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param(
            [Parameter(Mandatory)] [hashtable] $Cenario
        )

        $origem = Join-Path $pastaDosProjetos $Cenario.Projeto
        $caminhoDaEntrada = $null
        if ($Cenario.Entrada) {
            $caminhoDaEntrada = Join-Path $origem $Cenario.Entrada
        }

        $projetoNoLinux = Copy-ProjetoParaDistribuicao -Distribuicao $nomeDaDistribuicao -Origem $origem
        try {
            $argumentos = @($Cenario.NoLinux | ForEach-Object { $_.Replace('<projeto>', $projetoNoLinux) })
            $variaveis = @{}
            if ($Cenario.VariaveisNoLinux) {
                foreach ($nome in $Cenario.VariaveisNoLinux.Keys) {
                    $variaveis[$nome] = $Cenario.VariaveisNoLinux[$nome].Replace('<projeto>', $projetoNoLinux)
                }
            }
            $resultado = Invoke-AnsibleNativo -Distribuicao $nomeDaDistribuicao -Pasta $projetoNoLinux -Comando $Cenario.Comando -Argumentos $argumentos -CaminhoDaEntrada $caminhoDaEntrada -Variaveis $variaveis

            return [pscustomobject]@{
                CodigoDeSaida = $resultado.CodigoDeSaida
                Saida         = Format-SaidaDoAnsible -Texto $resultado.Saida -PastasDoProjeto $projetoNoLinux
                Erro          = Format-SaidaDoAnsible -Texto $resultado.Erro -PastasDoProjeto $projetoNoLinux
                Arquivos      = @(Get-ArquivoDoProjeto -Distribuicao $nomeDaDistribuicao -Pasta $projetoNoLinux)
            }
        }
        finally {
            Remove-PastaDaDistribuicao -Distribuicao $nomeDaDistribuicao -Pasta $projetoNoLinux
        }
    }

    function Invoke-CenarioNoWinPlaybook {
        <#
        .SYNOPSIS
        Executa o cenário pelos shims do WinPlaybook, a partir de uma cópia do projeto no Windows.

        .DESCRIPTION
        Com PastaDoProjeto = DiscoDoLinux, a cópia fica no disco do Linux da distribuição, e o
        Windows a vê pelo caminho \\wsl.localhost. Com Entrada, o comando recebe esse arquivo
        do projeto pelo pipeline, no PowerShell, ou pela entrada padrão, nos outros programas.
        Com Variaveis, o teste define essas variáveis de ambiente do Windows durante a chamada.
        Pelo PowerShell, o console usa a página de código do Windows, como num terminal novo.
        Devolve um objeto com CodigoDeSaida, Saida, Erro e Arquivos, com a pasta do projeto
        trocada por <projeto>.

        .PARAMETER Cenario
        O cenário, com Projeto, Comando e os argumentos no formato do Windows (NoWindows).

        .PARAMETER Chamador
        Quem chama o shim: PowerShell, que executa o .ps1, ou OutroPrograma, que executa o .exe.

        .EXAMPLE
        $noWinPlaybook = Invoke-CenarioNoWinPlaybook -Cenario $cenario -Chamador 'PowerShell'
        #>
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param(
            [Parameter(Mandatory)] [hashtable] $Cenario,
            [Parameter(Mandatory)] [ValidateSet('PowerShell', 'OutroPrograma')] [string] $Chamador
        )

        $origem = Join-Path $pastaDosProjetos $Cenario.Projeto
        $caminhoDaEntrada = $null
        if ($Cenario.Entrada) {
            $caminhoDaEntrada = Join-Path $origem $Cenario.Entrada
        }

        $ficaNoDiscoDoLinux = $Cenario.PastaDoProjeto -eq 'DiscoDoLinux'
        if ($ficaNoDiscoDoLinux) {
            $projetoNoLinux = Copy-ProjetoParaDistribuicao -Distribuicao $nomeDaDistribuicao -Origem $origem
            $projeto = "\\wsl.localhost\$nomeDaDistribuicao" + $projetoNoLinux.Replace('/', '\')
        }
        else {
            $projeto = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            Copy-Item -LiteralPath $origem -Destination $projeto -Recurse
        }

        $valoresOriginais = @{}
        try {
            $argumentos = @($Cenario.NoWindows | ForEach-Object { $_.Replace('<projeto>', $projeto) })
            if ($Cenario.Variaveis) {
                foreach ($nome in $Cenario.Variaveis.Keys) {
                    $valoresOriginais[$nome] = [Environment]::GetEnvironmentVariable($nome)
                    Set-Item -LiteralPath "Env:$nome" -Value $Cenario.Variaveis[$nome].Replace('<projeto>', $projeto)
                }
            }

            $ehChamadoPeloPowerShell = $Chamador -eq 'PowerShell'
            if ($ehChamadoPeloPowerShell) {
                $codificacaoDoConsole = [Console]::OutputEncoding
                [Console]::OutputEncoding = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
                Push-Location -LiteralPath $projeto
                try {
                    $resultado = Invoke-ScriptDePowerShell -Caminho (Join-Path $pastaDosShims "$($Cenario.Comando).ps1") -Argumentos $argumentos -CaminhoDaEntrada $caminhoDaEntrada
                }
                finally {
                    Pop-Location
                    [Console]::OutputEncoding = $codificacaoDoConsole
                }
            }
            else {
                $linhaDeComando = ConvertTo-LinhaDeComando -Argumentos $argumentos
                $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims "$($Cenario.Comando).exe") -Argumentos $linhaDeComando -PastaDeTrabalho $projeto -CaminhoDaEntrada $caminhoDaEntrada
            }

            $projetoNaDistribuicao = ConvertTo-CaminhoNaDistribuicao -Distribuicao $nomeDaDistribuicao -Caminho $projeto
            return [pscustomobject]@{
                CodigoDeSaida = $resultado.CodigoDeSaida
                Saida         = Format-SaidaDoAnsible -Texto $resultado.Saida -PastasDoProjeto $projetoNaDistribuicao
                Erro          = Format-SaidaDoAnsible -Texto $resultado.Erro -PastasDoProjeto $projetoNaDistribuicao
                Arquivos      = @(Get-ArquivoDoProjeto -Distribuicao $nomeDaDistribuicao -Pasta $projeto)
            }
        }
        finally {
            foreach ($nome in $valoresOriginais.Keys) {
                Remove-Item -LiteralPath "Env:$nome" -ErrorAction SilentlyContinue
                if ($null -ne $valoresOriginais[$nome]) {
                    Set-Item -LiteralPath "Env:$nome" -Value $valoresOriginais[$nome]
                }
            }
            if ($ficaNoDiscoDoLinux) {
                Remove-PastaDaDistribuicao -Distribuicao $nomeDaDistribuicao -Pasta $projetoNoLinux
            }
        }
    }
}

AfterAll {
    Remove-Module WinPlaybook
    $env:LOCALAPPDATA = $localAppDataOriginal
}

Describe 'Comportamento nativo do Ansible' {
    Context 'quando <Descricao>' -ForEach $cenarios {
        BeforeAll {
            $cenario = $_
            $nativo = Invoke-CenarioNativo -Cenario $cenario
        }

        Context 'quando é chamado <Nome>' -ForEach @(
            @{ Chamador = 'PowerShell'; Nome = 'pelo PowerShell' }
            @{ Chamador = 'OutroPrograma'; Nome = 'por outro programa' }
        ) {
            BeforeAll {
                $noWinPlaybook = Invoke-CenarioNoWinPlaybook -Cenario $cenario -Chamador $Chamador
            }

            It 'termina com o mesmo código de saída' {
                $noWinPlaybook.CodigoDeSaida | Should-Be $nativo.CodigoDeSaida -Because $noWinPlaybook.Erro
            }

            It 'mostra a mesma saída' {
                $noWinPlaybook.Saida | Should-Be $nativo.Saida
            }

            It 'mostra os mesmos erros' {
                $noWinPlaybook.Erro | Should-Be $nativo.Erro
            }

            It 'deixa os mesmos arquivos no projeto' {
                Should-BeCollection -Actual $noWinPlaybook.Arquivos -Expected $nativo.Arquivos
            }
        }
    }
}
