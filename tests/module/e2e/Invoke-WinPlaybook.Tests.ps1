BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/AgenteSsh.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')
    $caminhoDoModulo = (Resolve-Path (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1')).Path
    Import-Module $caminhoDoModulo -Force

    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste

    $localAppDataOriginal = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'
    Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao

    $projetoOla = Join-Path $PSScriptRoot '../data/projects/ola'
    $projetoComViolacoesDeLint = Join-Path $PSScriptRoot '../data/projects/violacao-de-lint'
    $projetoComConfiguracao = Join-Path $PSScriptRoot '../data/projects/configuracao-do-projeto'
    $projetoComInventario = Join-Path $PSScriptRoot '../data/projects/inventario'
    $projetoComSincronizacao = Join-Path $PSScriptRoot '../data/projects/sincronizacao'

    $vigia = Start-VigiaDeTesteTravado -Segundos 300
}

AfterAll {
    Stop-VigiaDeTesteTravado -Vigia $vigia
    Remove-Module WinPlaybook
    $env:LOCALAPPDATA = $localAppDataOriginal
}

Describe 'Invoke-WinPlaybook' {
    BeforeEach {
        Update-VigiaDeTesteTravado -Vigia $vigia
    }

    Context 'quando é chamado da pasta do projeto' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'projeto'
            Copy-Item $projetoOla $projeto -Recurse
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'executa o playbook' {
            $saida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }

        It 'propaga o código de saída do comando' {
            $saida = Invoke-WinPlaybook sh -c 'exit 3' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 3 -Because $saida
        }

        It 'passa os argumentos sem que um shell os interprete' {
            $saida = Invoke-WinPlaybook printf '%s|' '$HOME' '*' 'a b' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*$HOME|`*|a b|*'
        }

        It 'aceita um caminho relativo do Windows' {
            $saida = Invoke-WinPlaybook ansible-playbook .\site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }

        It 'aceita um caminho absoluto do Windows dentro do projeto' {
            $saida = Invoke-WinPlaybook ansible-playbook (Join-Path $projeto 'site.yml') 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }

        Context 'quando quem chama para nos erros' {
            BeforeAll {
                $acaoDeErroOriginal = $global:ErrorActionPreference
                $global:ErrorActionPreference = 'Stop'
            }

            AfterAll {
                $global:ErrorActionPreference = $acaoDeErroOriginal
            }

            It 'continua quando o comando escreve no stderr' {
                $saida = Invoke-WinPlaybook sh -c 'echo aviso >&2; echo terminou' 2>&1 | Out-String

                $LASTEXITCODE | Should-Be 0 -Because $saida
                $saida | Should-BeLikeString '*terminou*'
            }
        }
    }

    Context 'quando é chamado de uma subpasta de um repositório' {
        BeforeAll {
            $repositorio = Join-Path $TestDrive 'repositorio'
            Copy-Item $projetoOla $repositorio -Recurse
            $null = New-Item -ItemType Directory -Path (Join-Path $repositorio '.git') -Force
            $null = New-Item -ItemType Directory -Path (Join-Path $repositorio 'playbooks') -Force
            Push-Location (Join-Path $repositorio 'playbooks')
        }

        AfterAll {
            Pop-Location
        }

        It 'alcança arquivos acima da pasta atual' {
            $saida = Invoke-WinPlaybook ansible-playbook ../site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }
    }

    Context 'quando o playbook está fora da pasta atual' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'projeto-de-fora'
            Copy-Item $projetoOla $projeto -Recurse
            $outraPasta = Join-Path $TestDrive 'outra pasta'
            $null = New-Item -ItemType Directory -Path $outraPasta
            Push-Location $outraPasta
        }

        AfterAll {
            Pop-Location
        }

        It 'aceita o caminho absoluto do Windows dele' {
            $saida = Invoke-WinPlaybook ansible-playbook (Join-Path $projeto 'site.yml') 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }
    }

    Context 'quando o projeto tem violações de lint' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'violacao-de-lint'
            Copy-Item $projetoComViolacoesDeLint $projeto -Recurse
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'informa as violações' {
            $saida = Invoke-WinPlaybook ansible-lint site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-NotBe 0 -Because $saida
            $saida | Should-BeLikeString '*fqcn`[action-core`]*'
        }
    }

    Context 'quando o ansible.cfg do projeto define um caminho relativo para as collections' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'configuracao-do-projeto'
            Copy-Item $projetoComConfiguracao $projeto -Recurse
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'encontra as collections a partir do arquivo' {
            $saida =Invoke-WinPlaybook ansible-playbook playbooks/site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi da collection demo.test*'
        }
    }

    Context 'quando o inventário tem um host com conexão local' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'inventario'
            Copy-Item $projetoComInventario $projeto -Recurse
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'executa um módulo nesse host' {
            $saida = Invoke-WinPlaybook ansible -i inventario.yml servidores -m ansible.builtin.ping 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*"ping": "pong"*'
        }
    }

    Context 'quando o playbook copia uma pasta com o ansible.posix.synchronize' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'sincronizacao'
            Copy-Item $projetoComSincronizacao $projeto -Recurse
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'copia os arquivos com o rsync da distribuição' {
            $saida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            Get-Content -LiteralPath (Join-Path $projeto 'copia/ola.txt') -Raw | Should-BeLikeString 'oi do rsync*'
        }
    }

    Context 'quando a pasta .ssh do Windows tem uma chave e o known_hosts' {
        BeforeAll {
            Push-Location $TestDrive
            $pastaDoSsh = Get-PastaDoSshDeTeste
            $nomeDaChave = "id_ed25519_$([guid]::NewGuid().ToString('N'))"
            $linhasDaChave = @(Invoke-WinPlaybook sh -c 'ssh-keygen -q -t ed25519 -N "" -C winplaybook-teste -f "$1" && cat "$1" "$1.pub" && rm -f "$1" "$1.pub"' winplaybook "/tmp/$nomeDaChave")
            $chavePrivada = ($linhasDaChave[0..($linhasDaChave.Count - 2)] -join "`n") + "`n"
            [IO.File]::WriteAllText((Join-Path $pastaDoSsh $nomeDaChave), $chavePrivada)
            $caminhoDoKnownHosts = Join-Path $pastaDoSsh 'known_hosts'
            [IO.File]::WriteAllText($caminhoDoKnownHosts, "exemplo.winplaybook.teste $($linhasDaChave[-1])`n")
        }

        AfterAll {
            Remove-Item -LiteralPath (Join-Path $pastaDoSsh $nomeDaChave), $caminhoDoKnownHosts -Force
            Pop-Location
        }

        It 'aceita a chave privada criada no Windows' {
            $saida = Invoke-WinPlaybook ssh-keygen -y -f "/home/winplaybook/.ssh/$nomeDaChave" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*ssh-ed25519 *'
        }

        It 'reconhece os hosts do known_hosts do Windows' {
            $saida = Invoke-WinPlaybook ssh-keygen -F exemplo.winplaybook.teste 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*exemplo.winplaybook.teste*'
        }
    }

    Context 'quando o ssh grava um host novo no known_hosts' {
        BeforeAll {
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
        }

        It 'grava o nome do host sem hash, como o ssh do Windows' {
            $saida = Invoke-WinPlaybook ssh -G exemplo.winplaybook.teste 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*hashknownhosts no*'
        }

        It 'conecta com o nome do usuário do Windows quando a conexão não define um usuário' {
            $saida = Invoke-WinPlaybook ssh -G exemplo.winplaybook.teste 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*user usuario-de-teste*'
        }
    }

    Context 'quando o perfil do Windows tem um .ansible.cfg' {
        BeforeAll {
            $pastaDoPerfil = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinPlaybookTestes\perfil'
            $caminhoDoConfig = Join-Path $pastaDoPerfil '.ansible.cfg'
            [IO.File]::WriteAllText($caminhoDoConfig, "[defaults]`nforks = 13`n")
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            Remove-Item -LiteralPath $caminhoDoConfig -Force
            Remove-Item -LiteralPath (Join-Path $pastaDoPerfil '.ansible\roles\role_de_teste') -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'usa a configuração do perfil quando a pasta não tem um ansible.cfg' {
            $saida = Invoke-WinPlaybook ansible-config dump --only-changed 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*DEFAULT_FORKS*= 13*'
        }

        It 'guarda as roles da pasta pessoal do Ansible no perfil do Windows' {
            $saida = Invoke-WinPlaybook sh -c 'ansible-galaxy role init --init-path ~/.ansible/roles role_de_teste' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            Test-Path -LiteralPath (Join-Path $pastaDoPerfil '.ansible\roles\role_de_teste\tasks\main.yml') | Should-BeTrue -Because $saida
        }
    }

    Context 'quando o config da pasta .ssh do Windows liga o hash do known_hosts' {
        BeforeAll {
            Push-Location $TestDrive
            $caminhoDoConfig = Join-Path (Get-PastaDoSshDeTeste) 'config'
            [IO.File]::WriteAllText($caminhoDoConfig, "HashKnownHosts yes`n")
        }

        AfterAll {
            Remove-Item -LiteralPath $caminhoDoConfig -Force
            Pop-Location
        }

        It 'segue o config do usuário' {
            $saida = Invoke-WinPlaybook ssh -G exemplo.winplaybook.teste 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*hashknownhosts yes*'
        }
    }

    Context 'quando o config da pasta .ssh do Windows tem caminhos do Windows' {
        BeforeAll {
            Push-Location $TestDrive
            $pastaDoSsh = Get-PastaDoSshDeTeste
            $caminhoDoConfig = Join-Path $pastaDoSsh 'config'
            $linhas = @(
                'Host servidor-do-windows'
                "    IdentityFile $pastaDoSsh\id_do_windows"
                '    IdentityAgent \\.\pipe\openssh-ssh-agent'
                '    ProxyCommand C:\Windows\System32\OpenSSH\ssh.exe -W %h:%p bastiao'
                "    UserKnownHostsFile `"$env:SystemDrive\Pasta Com Espaco\known_hosts`""
            )
            [IO.File]::WriteAllText($caminhoDoConfig, ($linhas -join "`n") + "`n")
        }

        AfterAll {
            Remove-Item -LiteralPath $caminhoDoConfig -Force
            Pop-Location
        }

        It 'usa <Descricao>' -ForEach @(
            @{ Descricao = 'a chave da pasta .ssh pelo ~/.ssh da distribuição'; Esperado = '*identityfile ~/.ssh/id_do_windows*' }
            @{ Descricao = 'o agente pelo SSH_AUTH_SOCK'; Esperado = '*identityagent SSH_AUTH_SOCK*' }
            @{ Descricao = 'o ssh da distribuição no ProxyCommand'; Esperado = '*proxycommand ssh -W %h:%p bastiao*' }
            @{ Descricao = 'o caminho com espaço convertido para a raiz de montagem'; Esperado = '*userknownhostsfile /mnt/?/Pasta Com Espaco/known_hosts*' }
            @{ Descricao = 'ainda o config da distribuição, depois do config do usuário'; Esperado = '*user usuario-de-teste*' }
        ) {
            $saida = Invoke-WinPlaybook ssh -G servidor-do-windows 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString $Esperado
        }

        It 'mantém o config do Windows como estava' {
            $null = Invoke-WinPlaybook ssh -G servidor-do-windows 2>&1

            Get-Content -LiteralPath $caminhoDoConfig -Raw | Should-BeLikeString '*ProxyCommand C:\Windows\System32\OpenSSH\ssh.exe*'
        }
    }

    Context 'quando o agente SSH do Windows está rodando' {
        BeforeAll {
            $agente = Start-AgenteSshFalso
            $parametrosDoRelay = @{
                CaminhoDoRelay = Join-Path $TestDrive 'relay-compilado/relay-do-agente-ssh.exe'
                PastaDosShims  = Join-Path $TestDrive 'shims-com-relay'
                Distribuicao   = $nomeDaDistribuicao
                Pipe           = $agente.Nome
            }
            InModuleScope WinPlaybook -Parameters $parametrosDoRelay {
                $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao
                New-ExecutavelDoRelay -Caminho $CaminhoDoRelay
                Install-RelayDoAgenteSsh -CaminhoDoExecutavel $CaminhoDoRelay -PastaDosShims $PastaDosShims -Distribuicao $Distribuicao -RaizDeMontagem $raizDeMontagem
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = $raizDeMontagem; ShimFolder = $PastaDosShims; SshAgentPipe = $Pipe }
            }
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            Stop-AgenteSshFalso -Agente $agente
            Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao
        }

        It 'o ssh da distribuição usa as chaves do agente' {
            $saida = Invoke-WinPlaybook ssh-add -l 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString "*$($agente.Comentario)*"
        }

        It 'propaga o código de saída do comando' {
            $saida = Invoke-WinPlaybook sh -c 'exit 3' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 3 -Because $saida
        }

        It 'entrega ao comando o que chega pelo pipeline' {
            $saida = 'oi do pipeline' | Invoke-WinPlaybook cat 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do pipeline*'
        }

        It 'não deixa o socket nem o socat na distribuição depois do comando' {
            $null = Invoke-WinPlaybook ssh-add -l 2>&1

            $sobras = InModuleScope WinPlaybook -Parameters @{ Distribuicao = $nomeDaDistribuicao } {
                Invoke-ScriptNaDistribuicao -Distribuicao $Distribuicao -Script 'ls -d /tmp/winplaybook-agente.* 2> /dev/null; cat /proc/[0-9]*/comm 2> /dev/null | grep -x socat' -Usuario 'root'
            }
            $sobras.Saida | Should-Be ''
        }

        It 'encerra o comando na distribuição quando o processo do Windows termina' {
            $resultado = Get-SobraDeComandoInterrompido -CaminhoDoModulo $caminhoDoModulo -Distribuicao $nomeDaDistribuicao -PastaDeTrabalho $TestDrive

            $resultado.ComecouNaDistribuicao | Should-BeTrue
            $resultado.ProcessosQueSobraram | Should-Be 0
        }
    }

    Context 'quando o localhost_windows está desligado' {
        BeforeAll {
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
        }

        It 'não tem o host localhost_windows' {
            $saida = Invoke-WinPlaybook ansible localhost_windows --list-hosts 2>&1 | Out-String

            $saida | Should-BeLikeString '*hosts (0)*'
        }
    }

    Context 'quando o localhost_windows está ligado' {
        BeforeAll {
            InModuleScope WinPlaybook -Parameters @{ Distribuicao = $nomeDaDistribuicao } {
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = (Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao); LocalhostWindowsPort = 47022; LocalhostWindowsUser = 'eu' }
            }
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao
        }

        It 'tem o host localhost_windows sem que ele esteja no inventário' {
            $saida = Invoke-WinPlaybook ansible localhost_windows --list-hosts 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*hosts (1)*localhost_windows*'
        }

        It 'conecta no Windows pelo SSH do 127.0.0.1, com o shell do cmd' {
            $saida = Invoke-WinPlaybook ansible-inventory --host localhost_windows 2> $null | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $variaveis = $saida | ConvertFrom-Json
            $variaveis.ansible_host | Should-Be '127.0.0.1'
            $variaveis.ansible_port | Should-Be 47022
            $variaveis.ansible_user | Should-Be 'eu'
            $variaveis.ansible_connection | Should-Be 'ssh'
            $variaveis.ansible_shell_type | Should-Be 'cmd'
        }

        It 'deixa o localhost_windows fora do grupo all, como o localhost' {
            $saida = Invoke-WinPlaybook ansible all --list-hosts 2>&1 | Out-String

            $saida | Should-BeLikeString '*hosts (0)*'
        }
    }

    Context 'quando o localhost_windows é ligado numa máquina descartável' -Skip:(-not $env:WINPLAYBOOK_TEST_MAQUINA_DESCARTAVEL) {
        BeforeAll {
            $parametrosDoRelay = @{
                CaminhoDoRelay = Join-Path $TestDrive 'relay-do-localhost-windows/relay-de-rede.exe'
                PastaDosShims  = Join-Path $TestDrive 'shims-do-localhost-windows'
                Distribuicao   = $nomeDaDistribuicao
            }
            InModuleScope WinPlaybook -Parameters $parametrosDoRelay {
                $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao
                New-ExecutavelDoRelayDeRede -Caminho $CaminhoDoRelay
                Install-RelayDeRede -CaminhoDoExecutavel $CaminhoDoRelay -PastaDosShims $PastaDosShims -Distribuicao $Distribuicao -RaizDeMontagem $raizDeMontagem
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = $raizDeMontagem; ShimFolder = $PastaDosShims }
            }
            Enable-WinPlaybookLocalhost -Confirm:$false
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            Disable-WinPlaybookLocalhost -Confirm:$false
            Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao
        }

        It 'executa um módulo do ansible.windows no próprio Windows' {
            $saida = Invoke-WinPlaybook ansible localhost_windows -m ansible.windows.win_ping 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*"ping": "pong"*'
        }

        It 'executa os comandos com o usuário atual do Windows' {
            $saida = Invoke-WinPlaybook ansible localhost_windows -m ansible.windows.win_command -a 'whoami' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString "*$($env:USERNAME)*"
        }

        Context 'quando roda o playbook do tutorial da documentação' {
            BeforeAll {
                $projeto = Join-Path $TestDrive 'primeiro-playbook'
                Copy-Item (Join-Path $PSScriptRoot '../data/projects/primeiro-playbook') $projeto -Recurse
                $pastaCriada = Join-Path $HOME 'ola-ansible'
                Push-Location $projeto
                $primeiraSaida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String
                $primeiroCodigo = $LASTEXITCODE
                $segundaSaida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String
                $segundoCodigo = $LASTEXITCODE
            }

            AfterAll {
                Pop-Location
                Remove-Item -LiteralPath $pastaCriada -Recurse -Force -ErrorAction SilentlyContinue
            }

            It 'cria a pasta e o arquivo no perfil do Windows' {
                $primeiroCodigo | Should-Be 0 -Because $primeiraSaida
                $primeiraSaida | Should-BeLikeString '*localhost_windows*ok=4*changed=2*'
                Get-Content -LiteralPath (Join-Path $pastaCriada 'leia-me.txt') -Raw | Should-Be 'Este arquivo foi criado pelo Ansible.'
            }

            It 'não muda nada na segunda vez' {
                $segundoCodigo | Should-Be 0 -Because $segundaSaida
                $segundaSaida | Should-BeLikeString '*localhost_windows*ok=4*changed=0*'
            }
        }
    }

    Context 'quando a pasta do projeto está numa <Descricao>' -ForEach @(
        @{ Descricao = 'unidade criada com o subst'; Tipo = 'subst' }
        @{ Descricao = 'unidade de rede mapeada'; Tipo = 'rede' }
        @{ Descricao = 'pasta de rede (UNC)'; Tipo = 'unc' }
    ) {
        BeforeAll {
            $projeto = Join-Path $TestDrive "projeto-$Tipo"
            Copy-Item $projetoOla $projeto -Recurse
            $caminhoDeRede = '\\localhost\' + $projeto.Substring(0, 1) + '$' + $projeto.Substring(2)
            $letraLivre = [char[]] ([int][char]'Z'..[int][char]'H') | Where-Object { -not (Test-Path -LiteralPath "${_}:\") } | Select-Object -First 1
            $pastaDeTrabalho = $caminhoDeRede
            if ($Tipo -eq 'subst') {
                $null = subst.exe "${letraLivre}:" $projeto
                $pastaDeTrabalho = "${letraLivre}:\"
            }
            if ($Tipo -eq 'rede') {
                $null = net.exe use "${letraLivre}:" $caminhoDeRede
                $pastaDeTrabalho = "${letraLivre}:\"
            }
            Push-Location -LiteralPath $pastaDeTrabalho
        }

        AfterAll {
            Pop-Location
            if ($Tipo -eq 'subst') {
                $null = subst.exe "${letraLivre}:" /D
            }
            if ($Tipo -eq 'rede') {
                $null = net.exe use "${letraLivre}:" /delete /y
            }
        }

        It 'executa o playbook' {
            $saida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }

        It 'aceita o caminho absoluto do playbook' {
            $saida = Invoke-WinPlaybook ansible-playbook (Join-Path $pastaDeTrabalho 'site.yml') 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do WinPlaybook*'
        }
    }

    Context 'quando o Windows confia em certificados raiz' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'certificados'
            $null = New-Item -ItemType Directory -Path $projeto
            $linhas = @(
                'import hashlib, os, re, ssl, sys'
                "caminho = ssl.get_default_verify_paths().cafile if sys.argv[1] == 'padrao' else os.environ[sys.argv[1]]"
                'ssl.create_default_context(cafile=caminho)'
                'with open(caminho) as arquivo:'
                "    blocos = re.findall(r'-----BEGIN CERTIFICATE-----.+?-----END CERTIFICATE-----', arquivo.read(), re.DOTALL)"
                'for bloco in blocos:'
                '    print(hashlib.sha1(ssl.PEM_cert_to_DER_cert(bloco)).hexdigest().upper())'
            )
            [IO.File]::WriteAllText((Join-Path $projeto 'listar_certificados.py'), ($linhas -join "`n") + "`n")
            $impressoesDoWindows = @(InModuleScope WinPlaybook { Get-CertificadoRaizDoWindows } | ForEach-Object { $_.Thumbprint })
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'confia em todos os certificados raiz do Windows pelo <_>' -ForEach @('padrao', 'SSL_CERT_FILE', 'REQUESTS_CA_BUNDLE', 'CURL_CA_BUNDLE', 'GIT_SSL_CAINFO') {
            $saida = @(Invoke-WinPlaybook python3 listar_certificados.py $_ 2>&1)

            $LASTEXITCODE | Should-Be 0 -Because ($saida -join "`n")
            @($impressoesDoWindows | Where-Object { $saida -notcontains $_ }) | Should-BeCollection @()
        }

        It 'mantém os certificados do Debian' {
            $saida = @(Invoke-WinPlaybook python3 listar_certificados.py padrao 2>&1)

            $saida.Count | Should-BeGreaterThan ($impressoesDoWindows.Count + 100)
        }

        It 'usa a variável de certificados que o Windows define' {
            $caminhoNoWindows = Join-Path $TestDrive 'minha-ca.pem'
            $env:CURL_CA_BUNDLE = $caminhoNoWindows

            try {
                $saida = Invoke-WinPlaybook printenv CURL_CA_BUNDLE 2>&1 | Out-String
            }
            finally {
                Remove-Item -LiteralPath 'Env:CURL_CA_BUNDLE'
            }

            $saida.Trim() | Should-Be ('/mnt/' + $caminhoNoWindows.Substring(0, 1).ToLowerInvariant() + $caminhoNoWindows.Substring(2).Replace('\', '/'))
        }
    }

    Context 'quando o perfil do Windows tem um .gitconfig' {
        BeforeAll {
            $perfilDeTeste = Join-Path $TestDrive 'perfil-com-git'
            $null = New-Item -ItemType Directory -Path $perfilDeTeste
            $linhas = @(
                '[user]'
                '    name = Pessoa do Windows'
                '[core]'
                '    sshCommand = C:/Windows/System32/OpenSSH/ssh.exe'
                '    excludesFile = C:\\Users\\eu\\.gitignore_global'
                '[credential]'
                '    helper = manager'
            )
            [IO.File]::WriteAllText((Join-Path $perfilDeTeste '.gitconfig'), ($linhas -join "`n") + "`n")
            $perfilOriginal = $env:USERPROFILE
            $env:USERPROFILE = $perfilDeTeste
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            $env:USERPROFILE = $perfilOriginal
        }

        It 'usa <Descricao>' -ForEach @(
            @{ Descricao = 'o usuário do .gitconfig do Windows'; Chave = 'user.name'; Esperado = 'Pessoa do Windows' }
            @{ Descricao = 'o ssh da distribuição no lugar do ssh.exe'; Chave = 'core.sshCommand'; Esperado = 'ssh' }
            @{ Descricao = 'o caminho do Windows convertido para a raiz de montagem'; Chave = 'core.excludesFile'; Esperado = '/mnt/c/Users/eu/.gitignore_global' }
        ) {
            $saida = Invoke-WinPlaybook git config --get $Chave 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida.Trim() | Should-Be $Esperado
        }

        It 'usa o Git Credential Manager do Windows como credential.helper com o git.exe de <PastaDoGit> e o gerenciador em <PastaDoGerenciador>' -ForEach @(
            @{ PastaDoGit = 'cmd'; PastaDoGerenciador = 'mingw64\bin' }
            @{ PastaDoGit = 'bin'; PastaDoGerenciador = 'mingw64\bin' }
            @{ PastaDoGit = 'mingw64\bin'; PastaDoGerenciador = 'mingw64\libexec\git-core' }
            @{ PastaDoGit = 'cmd'; PastaDoGerenciador = 'ucrt64\bin' }
            @{ PastaDoGit = 'ucrt64\bin'; PastaDoGerenciador = 'ucrt64\bin' }
        ) {
            $raizDoGit = Join-Path $TestDrive "git-$([guid]::NewGuid().ToString('N'))\Git"
            $pastaDoExeDoGit = Join-Path $raizDoGit $PastaDoGit
            $pastaDoExeDoGerenciador = Join-Path $raizDoGit $PastaDoGerenciador
            $null = New-Item -ItemType Directory -Path $pastaDoExeDoGit, $pastaDoExeDoGerenciador -Force
            [IO.File]::WriteAllText((Join-Path $pastaDoExeDoGit 'git.exe'), '')
            [IO.File]::WriteAllText((Join-Path $pastaDoExeDoGerenciador 'git-credential-manager.exe'), '')
            $pathOriginal = $env:Path
            $env:Path = (@($env:Path -split ';' | Where-Object { $_ -and -not (Test-Path -LiteralPath (Join-Path $_ 'git.exe')) }) + $pastaDoExeDoGit) -join ';'

            try {
                $saida = Invoke-WinPlaybook git config --get-all credential.helper 2>&1 | Out-String
            }
            finally {
                $env:Path = $pathOriginal
            }

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString "*/Git/$($PastaDoGerenciador.Replace('\', '/'))/git-credential-manager.exe*"
        }

        It 'mantém o .gitconfig do Windows como estava' {
            $null = Invoke-WinPlaybook git config --get user.name 2>&1

            Get-Content -LiteralPath (Join-Path $perfilDeTeste '.gitconfig') -Raw | Should-BeLikeString '*helper = manager*'
        }
    }

    Context 'quando o comando chama programas do Path do Windows' {
        BeforeAll {
            $pastaDeFerramentas = Join-Path $TestDrive 'ferramentas'
            $null = New-Item -ItemType Directory -Path $pastaDeFerramentas
            [IO.File]::WriteAllText((Join-Path $pastaDeFerramentas 'saudacao.bat'), "@echo off`r`necho oi do bat %1`r`n")
            Copy-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('System')) 'hostname.exe') -Destination (Join-Path $pastaDeFerramentas 'NomeDaMaquina.exe')
            [IO.File]::WriteAllText((Join-Path $TestDrive 'texto do windows.txt'), "conteudo lido pelo Windows`r`n")
            $pathOriginal = $env:Path
            $env:Path = "$env:Path;$pastaDeFerramentas"
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            $env:Path = $pathOriginal
        }

        It 'executa o <Descricao>' -ForEach @(
            @{ Descricao = 'cmd.exe pelo nome completo'; Comando = 'cmd.exe /c echo oi do cmd'; Esperado = '*oi do cmd*' }
            @{ Descricao = 'powershell pelo nome curto'; Comando = 'powershell -NoProfile -Command "Write-Output (6*7)"'; Esperado = '*42*' }
            @{ Descricao = '.bat pelo nome curto, com argumentos'; Comando = 'saudacao mundo'; Esperado = '*oi do bat mundo*' }
            @{ Descricao = '.exe pelo nome sem extensão em minúscula'; Comando = 'nomedamaquina'; Esperado = "*$([Environment]::MachineName)*" }
            @{ Descricao = 'programa do Windows com um caminho da distribuição no argumento'; Comando = 'cmd /c type "$PWD/texto do windows.txt"'; Esperado = '*conteudo lido pelo Windows*' }
            @{ Descricao = '.bat com um caminho do disco do Linux no argumento'; Comando = 'saudacao /tmp/qualquer'; Esperado = '*oi do bat *wsl*tmp*qualquer*' }
        ) {
            $saida = Invoke-WinPlaybook sh -c $Comando 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString $Esperado
        }

        It 'não executa os shims do WinPlaybook pelo Path' {
            $saida = Invoke-WinPlaybook sh -c 'command -v ansible-playbook' 2>&1 | Out-String

            $saida.Trim() | Should-Be '/home/winplaybook/.local/bin/ansible-playbook'
        }

        It 'usa o Python da distribuição na detecção de interpretador de um host local' {
            $saida = Invoke-WinPlaybook ansible all -i 'meu-pc,' -c local -m ansible.builtin.setup -a 'filter=ansible_python_version' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*/usr/bin/python3*'
        }
    }

    Context 'quando um comando do nó de controle mostra caminhos da distribuição' {
        BeforeAll {
            Push-Location $TestDrive
            $perfilDosTestes = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinPlaybookTestes\perfil'
        }

        AfterAll {
            Pop-Location
        }

        It 'mostra o disco da distribuição pelo caminho que o Windows abre, com barras invertidas' {
            $saida = Invoke-WinPlaybook ansible --version 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString ("*ansible python module location = " + [WildcardPattern]::Escape("\\wsl.localhost\$nomeDaDistribuicao\home\winplaybook\") + "*")
        }

        It 'mostra os plugins do usuário pela pasta deles no perfil do Windows, escapada como no Python' {
            $saida = Invoke-WinPlaybook ansible --version 2>&1 | Out-String

            $saida | Should-BeLikeString ("*configured module search path = *" + [WildcardPattern]::Escape("['$($perfilDosTestes.Replace('\', '\\'))\\.ansible\\plugins\\modules'") + "*")
        }

        It 'separa por ponto e vírgula uma lista de caminhos' {
            $saida = Invoke-WinPlaybook ansible --version 2>&1 | Out-String

            $saida | Should-BeLikeString ("*ansible collection location = " + [WildcardPattern]::Escape("$perfilDosTestes\.ansible\collections;\\wsl.localhost\$nomeDaDistribuicao\usr\share\ansible\collections") + "*")
        }

        It 'mostra as collections pela pasta delas no perfil do Windows' {
            $saida = Invoke-WinPlaybook ansible-config dump 2>&1 | Out-String

            $saida | Should-BeLikeString ("*" + [WildcardPattern]::Escape("COLLECTIONS_PATHS(default) = ['$($perfilDosTestes.Replace('\', '\\'))\\.ansible\\collections'") + "*")
        }

        It 'mantém os caminhos dos hosts na saída de um playbook' {
            $saida = Invoke-WinPlaybook ansible localhost -m ansible.builtin.stat -a 'path=/etc/hostname' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*"path": "/etc/hostname"*'
        }
    }

    Context 'quando o projeto usa caminhos relativos com barra invertida' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'caminhos-relativos-do-windows'
            $null = New-Item -ItemType Directory -Path (Join-Path $projeto 'inventario'), (Join-Path $projeto 'segredos'), (Join-Path $projeto 'roles\internas\role_interna\tasks'), (Join-Path $projeto 'files') -Force
            [IO.File]::WriteAllText((Join-Path $projeto 'ansible.cfg'), "[defaults]`r`ninventory = inventario\hosts.yml`r`nvault_password_file = segredos\senha.txt`r`nroles_path = roles\internas`r`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'inventario\hosts.yml'), "all:`r`n  hosts:`r`n    servidor-relativo:`r`n      ansible_connection: local`r`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'segredos\senha.txt'), "senha-de-teste`r`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'roles\internas\role_interna\tasks\main.yml'), "- ansible.builtin.debug:`r`n    msg: role achada pelo caminho relativo`r`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'files\dado.txt'), "conteudo relativo`r`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'site.yml'), "- hosts: servidor-relativo`r`n  gather_facts: false`r`n  roles: [role_interna]`r`n  tasks:`r`n    - ansible.builtin.debug:`r`n        msg: `"{{ lookup('ansible.builtin.file', 'files\\dado.txt') }}`"`r`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'segredo.yml'), "valor: segredo relativo`r`n")
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'lê o inventário do caminho relativo do ansible.cfg' {
            $saida = Invoke-WinPlaybook ansible-inventory --list 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*servidor-relativo*'
        }

        It 'usa a senha do vault do caminho relativo do ansible.cfg' {
            $saida = Invoke-WinPlaybook ansible-vault encrypt segredo.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            Get-Content -LiteralPath (Join-Path $projeto 'segredo.yml') -TotalCount 1 | Should-Be '$ANSIBLE_VAULT;1.1;AES256'
        }

        It 'acha a role e o arquivo pelos caminhos relativos' {
            $saida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*role achada pelo caminho relativo*'
            $saida | Should-BeLikeString '*conteudo relativo*'
        }
    }

    Context 'quando os arquivos do projeto têm caminhos do Windows' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'caminhos-do-windows'
            $null = New-Item -ItemType Directory -Path (Join-Path $projeto 'files'), (Join-Path $projeto 'roles-fora/role_de_fora/tasks') -Force
            [IO.File]::WriteAllText((Join-Path $projeto 'files/dado.txt'), "conteudo do arquivo do Windows`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'roles-fora/role_de_fora/tasks/main.yml'), "- ansible.builtin.debug:`n    msg: role achada pelo roles_path`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'ansible.cfg'), "[defaults]`nroles_path = $projeto\roles-fora`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'site.yml'), "- hosts: localhost`n  gather_facts: false`n  vars:`n    arquivo: $projeto\files\dado.txt`n  roles: [role_de_fora]`n  tasks:`n    - ansible.builtin.debug:`n        msg: `"{{ lookup('ansible.builtin.file', arquivo) }}`"`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'hosts.ini'), "meu-pc ansible_connection=local arquivo=$projeto\files\dado.txt`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'quebrado.yml'), "- hosts: localhost`n  tasks:`n    - debug: { msg: oi`n")
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'lê o arquivo do caminho do Windows numa variável do playbook' {
            $saida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*conteudo do arquivo do Windows*'
        }

        It 'acha a role pelo caminho do Windows do roles_path no ansible.cfg' {
            $saida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*role achada pelo roles_path*'
        }

        It 'converte o caminho do Windows de um chave=valor do -e' {
            $saida = Invoke-WinPlaybook ansible localhost -m ansible.builtin.debug -a 'var=pasta' -e "pasta=$projeto\files" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*\\files"*'
        }

        It 'converte o caminho do Windows de um chave=valor do -a' {
            $saida = Invoke-WinPlaybook ansible localhost -m ansible.builtin.stat -a "path=$projeto\files\dado.txt" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*"exists": true*'
        }

        It 'mostra o caminho do Windows do arquivo num erro' {
            $saida = Invoke-WinPlaybook ansible-playbook quebrado.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-NotBe 0 -Because $saida
            $saida | Should-BeLikeString ("*Origin: " + [WildcardPattern]::Escape("$projeto\quebrado.yml") + "*")
        }

        It 'mostra o caminho do Windows da configuração no ansible --version' {
            $saida = Invoke-WinPlaybook ansible --version 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString ("*config file = " + [WildcardPattern]::Escape("$projeto\ansible.cfg") + "*")
        }

        It 'mantém o caminho do Windows de uma variável do inventário INI' {
            $saida = Invoke-WinPlaybook ansible -i hosts.ini meu-pc -m ansible.builtin.debug -a "msg={{ lookup('ansible.builtin.file', arquivo) }}" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*conteudo do arquivo do Windows*'
        }
    }

    Context 'quando um script do projeto tem finais de linha CRLF' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'script-com-crlf'
            $null = New-Item -ItemType Directory -Path $projeto
            [IO.File]::WriteAllText((Join-Path $projeto 'ola.sh'), "#!/bin/sh`r`necho oi do script com CRLF`r`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'site.yml'), "- hosts: localhost`n  gather_facts: false`n  tasks:`n    - ansible.builtin.script: ola.sh`n      register: saida`n    - ansible.builtin.debug:`n        var: saida.stdout`n")
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
        }

        It 'executa o script pelo ansible.builtin.script' {
            $saida = Invoke-WinPlaybook ansible-playbook site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*oi do script com CRLF*'
        }

        It 'mantém o script do projeto como estava' {
            $null = Invoke-WinPlaybook ansible-playbook site.yml 2>&1

            [IO.File]::ReadAllText((Join-Path $projeto 'ola.sh')) | Should-Be "#!/bin/sh`r`necho oi do script com CRLF`r`n"
        }
    }

    Context 'quando um script de senha do vault ou de inventário está numa pasta do Windows' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'scripts-do-windows'
            $null = New-Item -ItemType Directory -Path $projeto
            $json = '{"todos": {"hosts": ["maquina-do-script"]}}'
            $arquivos = @{
                'senha.txt'      = "senha-do-teste`n"
                'senha.bat'      = "@echo senha-do-teste`r`n"
                'senha.cmd'      = "@echo senha-do-teste`r`n"
                'senha.ps1'      = "Write-Output 'senha-do-teste'`r`n"
                'senha.py'       = "print('senha-do-teste')`r`n"
                'senha.sh'       = "#!/bin/sh`r`necho senha-do-teste`r`n"
                'inventario.bat' = "@echo $json`r`n"
                'inventario.ps1' = "Write-Output '$json'`r`n"
                'inventario.py'  = "print('$json')`r`n"
                'inventario.sh'  = "echo '$json'`r`n"
                'segredo.yml'    = "valor: segredo-do-vault`n"
            }
            foreach ($nome in $arquivos.Keys) {
                [IO.File]::WriteAllText((Join-Path $projeto $nome), $arquivos[$nome])
            }
            Copy-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('System')) 'hostname.exe') -Destination (Join-Path $projeto 'senha.exe')
            [IO.File]::WriteAllText((Join-Path $projeto 'senha-do-exe.txt'), (hostname.exe | Out-String).Trim() + "`n")
            Copy-Item -LiteralPath (Join-Path $projeto 'segredo.yml') -Destination (Join-Path $projeto 'segredo-do-exe.yml')
            Push-Location $projeto
            $null = Invoke-WinPlaybook ansible-vault encrypt --vault-password-file senha.txt segredo.yml 2>&1
            $null = Invoke-WinPlaybook ansible-vault encrypt --vault-password-file senha-do-exe.txt segredo-do-exe.yml 2>&1
        }

        AfterAll {
            Pop-Location
        }

        It 'lê a senha do vault executando o <_>' -ForEach @('senha.bat', 'senha.cmd', 'senha.ps1', 'senha.py', 'senha.sh') {
            $saida = Invoke-WinPlaybook ansible-vault view --vault-password-file $_ segredo.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*segredo-do-vault*'
        }

        It 'lê a senha do vault executando o senha.exe' {
            $saida = Invoke-WinPlaybook ansible-vault view --vault-password-file senha.exe segredo-do-exe.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*segredo-do-vault*'
        }

        It 'lê a senha do vault do senha.txt como texto' {
            $saida = Invoke-WinPlaybook ansible-vault view --vault-password-file senha.txt segredo.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*segredo-do-vault*'
        }

        It 'lê o inventário dinâmico executando o <_>' -ForEach @('inventario.bat', 'inventario.ps1', 'inventario.py', 'inventario.sh') {
            $saida = Invoke-WinPlaybook ansible-inventory -i $_ --graph todos 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*@todos:*--maquina-do-script*'
        }
    }

    Context 'quando o projeto tem um pyproject.toml com o Ansible' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'projeto-com-uv'
            $null = New-Item -ItemType Directory -Path (Join-Path $projeto 'playbooks')
            $linhas = @(
                '[project]'
                'name = "projeto-com-uv"'
                'version = "0.1.0"'
                'requires-python = ">=3.11,<3.14"'
                'dependencies = ["ansible-core==2.19.*"]'
            )
            [IO.File]::WriteAllText((Join-Path $projeto 'pyproject.toml'), ($linhas -join "`n") + "`n")
            $projetoSemAnsible = Join-Path $TestDrive 'projeto-sem-ansible'
            $null = New-Item -ItemType Directory -Path $projetoSemAnsible
            [IO.File]::WriteAllText((Join-Path $projetoSemAnsible 'pyproject.toml'), "[project]`nname = `"outro`"`nversion = `"0.1.0`"`ndependencies = []`n")
            Push-Location (Join-Path $projeto 'playbooks')
        }

        AfterAll {
            Pop-Location
        }

        It 'usa o Ansible do projeto, achado a partir de uma subpasta' {
            $saida = Invoke-WinPlaybook ansible --version 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*core 2.19.*'
        }

        It 'não usa os comandos do ambiente global que o projeto não tem' {
            $saida = Invoke-WinPlaybook ansible-lint --version 2>&1 | Out-String

            $LASTEXITCODE | Should-NotBe 0 -Because $saida
        }

        It 'aceita caminhos do Windows no ambiente do projeto' {
            $caminhoNoWindows = Join-Path $projeto 'pyproject.toml'

            $saida = Invoke-WinPlaybook ansible localhost -m ansible.builtin.stat -a "path=$caminhoNoWindows" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*"exists": true*'
        }

        It 'deixa o ambiente fora da pasta do projeto' {
            $null = Invoke-WinPlaybook ansible --version 2>&1

            Test-Path -LiteralPath (Join-Path $projeto '.venv') | Should-BeFalse
        }

        It 'usa o ambiente global num projeto sem o Ansible no pyproject.toml' {
            Push-Location $projetoSemAnsible

            try {
                $saida = Invoke-WinPlaybook ansible-lint --version 2>&1 | Out-String
            }
            finally {
                Pop-Location
            }

            $LASTEXITCODE | Should-Be 0 -Because $saida
        }
    }

    Context 'quando o pyproject.toml do projeto declara uma ferramenta' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'projeto-com-ferramenta'
            $null = New-Item -ItemType Directory -Path $projeto
            $linhas = @(
                '[project]'
                'name = "projeto-com-ferramenta"'
                'version = "0.1.0"'
                'requires-python = ">=3.11,<3.14"'
                'dependencies = ["ansible-core==2.19.*", "yamllint"]'
            )
            [IO.File]::WriteAllText((Join-Path $projeto 'pyproject.toml'), ($linhas -join "`n") + "`n")
            $pastaDosShims = Join-Path $TestDrive 'shims-do-projeto'
            $null = New-Item -ItemType Directory -Path $pastaDosShims
            [IO.File]::WriteAllText((Join-Path $pastaDosShims 'ansible.exe'), 'executavel do shim')
            InModuleScope WinPlaybook -Parameters @{ Distribuicao = $nomeDaDistribuicao; Pasta = $pastaDosShims } {
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = (Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao); ShimFolder = $Pasta; ShimPowerShellPath = (Get-Process -Id $PID).Path }
            }
            Push-Location $projeto
            $saidaDoPrimeiroComando = Invoke-WinPlaybook ansible --version 2>&1 | Out-String
        }

        AfterAll {
            Pop-Location
            Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao
        }

        It 'cria o shim da ferramenta do projeto' {
            Test-Path -LiteralPath (Join-Path $pastaDosShims 'yamllint.exe') | Should-BeTrue -Because $saidaDoPrimeiroComando
        }

        It 'executa a ferramenta do projeto pelo shim novo' {
            $saida = & (Join-Path $pastaDosShims 'yamllint.ps1') --version 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*yamllint*'
        }

        It 'não cria shims para os comandos do próprio Python' {
            @(Get-ChildItem -LiteralPath $pastaDosShims -Filter 'python*') | Should-BeCollection @()
        }
    }

    Context 'quando o ansible-vault abre um editor' {
        BeforeAll {
            $pastaDoEditor = Join-Path $TestDrive 'editor'
            $null = New-Item -ItemType Directory -Path $pastaDoEditor
            [IO.File]::WriteAllText((Join-Path $pastaDoEditor 'editor-de-teste.bat'), "@echo segredo: escrito pelo editor do Windows> %1`r`n")
            $projeto = Join-Path $TestDrive 'vault-com-editor'
            $null = New-Item -ItemType Directory -Path $projeto
            [IO.File]::WriteAllText((Join-Path $projeto 'senha.txt'), "senha-do-teste`n")
            $pathOriginal = $env:Path
            $editorOriginal = $env:EDITOR
            $env:Path = "$env:Path;$pastaDoEditor"
            Push-Location $projeto
        }

        AfterAll {
            Pop-Location
            $env:Path = $pathOriginal
            Remove-Item -LiteralPath 'Env:EDITOR' -ErrorAction SilentlyContinue
            if ($null -ne $editorOriginal) {
                $env:EDITOR = $editorOriginal
            }
        }

        It 'cria o arquivo cifrado com o editor do EDITOR do Windows' {
            $env:EDITOR = 'editor-de-teste'
            $saidaDoCreate = Invoke-WinPlaybook script -qec 'ansible-vault create --vault-password-file senha.txt novo.yml' /dev/null 2>&1 | Out-String

            $saida = Invoke-WinPlaybook ansible-vault view --vault-password-file senha.txt novo.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because "$saidaDoCreate $saida"
            $saida | Should-BeLikeString '*segredo: escrito pelo editor do Windows*'
        }

        It 'não muda o editor dos outros comandos quando o Windows não define um' {
            Remove-Item -LiteralPath 'Env:EDITOR' -ErrorAction SilentlyContinue

            $saida = Invoke-WinPlaybook sh -c 'printf "[%s]" "$EDITOR"' 2>&1 | Out-String

            $saida.Trim() | Should-Be '[]'
        }
    }

    Context 'quando um comando passa do limite de tempo dos testes' {
        It 'encerra o comando e devolve o controle ao teste' {
            $vigiaCurto = Start-VigiaDeTesteTravado -Segundos 10
            $relogio = [Diagnostics.Stopwatch]::StartNew()

            try {
                $saida = Invoke-WinPlaybook sleep 300 2>&1 | Out-String
            }
            finally {
                Stop-VigiaDeTesteTravado -Vigia $vigiaCurto
            }

            $LASTEXITCODE | Should-NotBe 0 -Because $saida
            $relogio.Elapsed.TotalSeconds | Should-BeLessThan 120
        }
    }

    Context 'quando o log está no nível debug' {
        BeforeAll {
            $nivelOriginal = $env:WINPLAYBOOK_LOG
            $env:WINPLAYBOOK_LOG = 'debug'
            Push-Location $TestDrive
            $null = Invoke-WinPlaybook ansible --version 2>&1
            $log = Get-Content -LiteralPath (InModuleScope WinPlaybook { Get-CaminhoDoLog }) -Raw -Encoding UTF8
        }

        AfterAll {
            Pop-Location
            Remove-Item -LiteralPath 'Env:WINPLAYBOOK_LOG' -ErrorAction SilentlyContinue
            if ($null -ne $nivelOriginal) {
                $env:WINPLAYBOOK_LOG = $nivelOriginal
            }
        }

        It 'registra os argumentos e o tempo do comando' {
            $log | Should-BeLikeString '*`[DEBUG`]*ansible na pasta*"--version"*`[INFO`]*ansible saiu com 0 em * ms*'
        }

        It 'registra o tempo de cada preparação do supervisor na distribuição' {
            $log | Should-BeLikeString '*`[DEBUG`] `[supervisor *`] ansible: path do Windows: * ms, config do ssh: * ms*comando: * ms*'
        }
    }

    Context 'quando o processo do Windows termina no meio do comando' {
        It 'encerra o comando e os processos que ele criou na distribuição' {
            $resultado = Get-SobraDeComandoInterrompido -CaminhoDoModulo $caminhoDoModulo -Distribuicao $nomeDaDistribuicao -PastaDeTrabalho $TestDrive

            $resultado.ComecouNaDistribuicao | Should-BeTrue
            $resultado.ProcessosQueSobraram | Should-Be 0
        }
    }

    Context 'quando um serviço escuta no localhost do Windows' {
        BeforeAll {
            $parametrosDoRelay = @{
                CaminhoDoRelay = Join-Path $TestDrive 'relay-de-rede-compilado/relay-de-rede.exe'
                PastaDosShims  = Join-Path $TestDrive 'shims-com-relay-de-rede'
                Distribuicao   = $nomeDaDistribuicao
            }
            InModuleScope WinPlaybook -Parameters $parametrosDoRelay {
                $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao
                New-ExecutavelDoRelayDeRede -Caminho $CaminhoDoRelay
                Install-RelayDeRede -CaminhoDoExecutavel $CaminhoDoRelay -PastaDosShims $PastaDosShims -Distribuicao $Distribuicao -RaizDeMontagem $raizDeMontagem
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = $raizDeMontagem; ShimFolder = $PastaDosShims }
            }
            $escutaTemporaria = New-Object System.Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, 0)
            $escutaTemporaria.Start()
            $portaDoWindows = $escutaTemporaria.LocalEndpoint.Port
            $escutaTemporaria.Stop()
            $portaFechada = $portaDoWindows + 1
            $rotaPadrao = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos "-d $nomeDaDistribuicao -- ip -4 route show default"
            $ipDoWindowsNaRedeDoWsl = ($rotaPadrao.Saida -split '\s+')[2]
            $portaSoDoWindows = $portaDoWindows + 2
            $servidorSoDoWindows = Join-Path $TestDrive 'servidor-so-do-windows.ps1'
            [IO.File]::WriteAllText($servidorSoDoWindows, "`$escuta = New-Object System.Net.Sockets.TcpListener ([Net.IPAddress]::Parse('$ipDoWindowsNaRedeDoWsl'), $portaSoDoWindows)`r`n`$escuta.Start()`r`nwhile (`$true) { `$cliente = `$escuta.AcceptTcpClient(); `$dados = [Text.Encoding]::ASCII.GetBytes(`"oi so do windows`n`"); `$cliente.GetStream().Write(`$dados, 0, `$dados.Length); `$cliente.Close() }`r`n")
            $regraQueBloqueiaOCaminhoDireto = "table inet e2e_caminho_direto { chain saida { type filter hook output priority 0; policy accept; ip daddr $ipDoWindowsNaRedeDoWsl tcp dport $portaSoDoWindows drop; }; }"
            $null = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos "-d $nomeDaDistribuicao -u root -- nft `"$regraQueBloqueiaOCaminhoDireto`""
            $processoDoServidorSoDoWindows = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$servidorSoDoWindows`"" -WindowStyle Hidden -PassThru
            $servidor = Join-Path $TestDrive 'servidor-do-windows.ps1'
            [IO.File]::WriteAllText($servidor, "`$escuta = New-Object System.Net.Sockets.TcpListener ([Net.IPAddress]::Loopback, $portaDoWindows)`r`n`$escuta.Start()`r`nwhile (`$true) { `$cliente = `$escuta.AcceptTcpClient(); `$dados = [Text.Encoding]::ASCII.GetBytes(`"oi do windows`n`"); `$cliente.GetStream().Write(`$dados, 0, `$dados.Length); `$cliente.Close() }`r`n")
            $processoDoServidor = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$servidor`"" -WindowStyle Hidden -PassThru
            $linhasDoCliente = @(
                'import socket, sys'
                'conexao = socket.create_connection((sys.argv[1], int(sys.argv[2])), 5)'
                'print(conexao.recv(100).decode().strip())'
            )
            [IO.File]::WriteAllText((Join-Path $TestDrive 'cliente.py'), ($linhasDoCliente -join "`n") + "`n")
            $linhasDoServidorDaDistribuicao = @(
                'import socket, sys'
                'escuta = socket.create_server(("127.0.0.1", int(sys.argv[1])))'
                'conexao, _ = escuta.accept()'
                'conexao.sendall(b"oi da distribuicao\n")'
            )
            [IO.File]::WriteAllText((Join-Path $TestDrive 'servidor_da_distribuicao.py'), ($linhasDoServidorDaDistribuicao -join "`n") + "`n")
            Start-Sleep -Seconds 2
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            Stop-Process -Id $processoDoServidor.Id -Force -ErrorAction SilentlyContinue
            Stop-Process -Id $processoDoServidorSoDoWindows.Id -Force -ErrorAction SilentlyContinue
            $null = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos "-d $nomeDaDistribuicao -u root -- nft delete table inet e2e_caminho_direto"
            Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao
        }

        It 'alcança pelo Windows um destino que a distribuição não alcança direto' {
            $saida = Invoke-WinPlaybook python3 cliente.py $ipDoWindowsNaRedeDoWsl $portaSoDoWindows 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida.Trim() | Should-Be 'oi so do windows'
        }

        It 'deixa a rede da distribuição como estava quando o comando termina' {
            $null = Invoke-WinPlaybook python3 cliente.py 127.0.0.1 $portaDoWindows 2>&1

            $tabelas = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos "-d $nomeDaDistribuicao -u root -- nft list tables"

            $tabelas.Saida | Should-NotBeLikeString '*winplaybook*'
        }

        It 'interrompe a conexão quando o destino fora do localhost a recusa' {
            $saida = Invoke-WinPlaybook python3 cliente.py $ipDoWindowsNaRedeDoWsl $portaFechada 2>&1 | Out-String

            $saida | Should-BeLikeString '*ConnectionResetError*'
        }

        It 'alcança o serviço do Windows pelo <_> da distribuição' -ForEach @('127.0.0.1', 'localhost', '::1') {
            $saida = Invoke-WinPlaybook python3 cliente.py $_ $portaDoWindows 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida.Trim() | Should-Be 'oi do windows'
        }

        It 'encontra o serviço do Windows pelo wait_for do Ansible' {
            $saida = Invoke-WinPlaybook ansible localhost -m ansible.builtin.wait_for -a "host=localhost port=$portaDoWindows timeout=10" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
        }

        It 'recusa a conexão numa porta em que o Windows não escuta' {
            $saida = Invoke-WinPlaybook python3 cliente.py 127.0.0.1 $portaFechada 2>&1 | Out-String

            $saida | Should-BeLikeString '*ConnectionRefusedError*'
        }

        It 'mantém na distribuição a porta em que ela também escuta' {
            $saida = Invoke-WinPlaybook sh -c "python3 servidor_da_distribuicao.py $portaDoWindows & sleep 3; python3 cliente.py 127.0.0.1 $portaDoWindows" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida.Trim() | Should-Be 'oi da distribuicao'
        }
    }

    Context 'quando o agente SSH do Windows não está rodando' {
        BeforeAll {
            $parametrosDoRelay = @{
                CaminhoDoRelay = Join-Path $TestDrive 'relay-sem-agente/relay-do-agente-ssh.exe'
                PastaDosShims  = Join-Path $TestDrive 'shims-sem-agente'
                Distribuicao   = $nomeDaDistribuicao
            }
            InModuleScope WinPlaybook -Parameters $parametrosDoRelay {
                $raizDeMontagem = Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao
                New-ExecutavelDoRelay -Caminho $CaminhoDoRelay
                Install-RelayDoAgenteSsh -CaminhoDoExecutavel $CaminhoDoRelay -PastaDosShims $PastaDosShims -Distribuicao $Distribuicao -RaizDeMontagem $raizDeMontagem
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = $raizDeMontagem; ShimFolder = $PastaDosShims; SshAgentPipe = "winplaybook-inexistente-$([guid]::NewGuid().ToString('N'))" }
            }
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao
        }

        It 'executa o comando sem o SSH_AUTH_SOCK' {
            $saida = Invoke-WinPlaybook sh -c 'printf "[%s]" "$SSH_AUTH_SOCK"' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida.Trim() | Should-Be '[]'
        }
    }

    Context 'quando o comando não está na distribuição' {
        BeforeAll {
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
        }

        It 'explica que falta o comando' {
            $mensagem = InModuleScope WinPlaybook { Get-Mensagem -Nome 'ComandoAusenteNoWsl' -Valores 'winplaybook-comando-inexistente' }

            $saida = (Invoke-WinPlaybook winplaybook-comando-inexistente 2>&1 | ForEach-Object { "$_" }) -join [Environment]::NewLine

            $LASTEXITCODE | Should-Be 127 -Because $saida
            $saida | Should-BeLikeString "*$mensagem*"
        }

        It 'recusa o programa do Windows com o mesmo nome' {
            $mensagem = InModuleScope WinPlaybook { Get-Mensagem -Nome 'ComandoAusenteNoWsl' -Valores 'cmd.exe' }

            $saida = (Invoke-WinPlaybook cmd.exe /c exit 0 2>&1 | ForEach-Object { "$_" }) -join [Environment]::NewLine

            $LASTEXITCODE | Should-Be 127 -Because $saida
            $saida | Should-BeLikeString "*$mensagem*"
        }
    }

    Context 'quando a distribuição do WinPlaybook não existe mais' {
        BeforeAll {
            InModuleScope WinPlaybook {
                Save-Configuracao -Configuracao @{ WslDistribution = 'WinPlaybookInexistente'; WslMountRoot = '/mnt/' }
            }
            Push-Location $TestDrive
        }

        AfterAll {
            Pop-Location
            Reset-ConfiguracaoDeTeste -Distribuicao $nomeDaDistribuicao
        }

        It 'explica como instalar de novo' {
            $mensagem = InModuleScope WinPlaybook { Get-Mensagem -Nome 'DistribuicaoNaoExisteMais' -Valores 'WinPlaybookInexistente' }

            { Invoke-WinPlaybook ansible --version 2>$null } | Should-Throw -ExceptionMessage $mensagem
        }
    }
}
