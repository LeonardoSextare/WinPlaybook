BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/AgenteSsh.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')
    $caminhoDoModulo = (Resolve-Path (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1')).Path
    Import-Module $caminhoDoModulo -Force

    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste

    $localAppDataOriginal = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'
    InModuleScope WinPlaybook -Parameters @{ Distribuicao = $nomeDaDistribuicao } {
        Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = (Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao) }
    }

    $projetoOla = Join-Path $PSScriptRoot '../data/projects/ola'
    $projetoComViolacoesDeLint = Join-Path $PSScriptRoot '../data/projects/violacao-de-lint'
    $projetoComConfiguracao = Join-Path $PSScriptRoot '../data/projects/configuracao-do-projeto'
    $projetoComInventario = Join-Path $PSScriptRoot '../data/projects/inventario'
    $projetoComSincronizacao = Join-Path $PSScriptRoot '../data/projects/sincronizacao'
}

AfterAll {
    Remove-Module WinPlaybook
    $env:LOCALAPPDATA = $localAppDataOriginal
}

Describe 'Invoke-WinPlaybook' {
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
            InModuleScope WinPlaybook -Parameters @{ Distribuicao = $nomeDaDistribuicao } {
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = (Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao) }
            }
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

    Context 'quando o comando chama programas do Path do Windows' {
        BeforeAll {
            $pastaDeFerramentas = Join-Path $TestDrive 'ferramentas'
            $null = New-Item -ItemType Directory -Path $pastaDeFerramentas
            [IO.File]::WriteAllText((Join-Path $pastaDeFerramentas 'saudacao.bat'), "@echo off`r`necho oi do bat %1`r`n")
            Copy-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('System')) 'hostname.exe') -Destination (Join-Path $pastaDeFerramentas 'NomeDaMaquina.exe')
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

    Context 'quando os arquivos do projeto têm caminhos do Windows' {
        BeforeAll {
            $projeto = Join-Path $TestDrive 'caminhos-do-windows'
            $null = New-Item -ItemType Directory -Path (Join-Path $projeto 'files'), (Join-Path $projeto 'roles-fora/role_de_fora/tasks') -Force
            [IO.File]::WriteAllText((Join-Path $projeto 'files/dado.txt'), "conteudo do arquivo do Windows`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'roles-fora/role_de_fora/tasks/main.yml'), "- ansible.builtin.debug:`n    msg: role achada pelo roles_path`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'ansible.cfg'), "[defaults]`nroles_path = $projeto\roles-fora`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'site.yml'), "- hosts: localhost`n  gather_facts: false`n  vars:`n    arquivo: $projeto\files\dado.txt`n  roles: [role_de_fora]`n  tasks:`n    - ansible.builtin.debug:`n        msg: `"{{ lookup('ansible.builtin.file', arquivo) }}`"`n")
            [IO.File]::WriteAllText((Join-Path $projeto 'hosts.ini'), "meu-pc ansible_connection=local arquivo=$projeto\files\dado.txt`n")
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
            $saida | Should-BeLikeString '*/files"*'
        }

        It 'converte o caminho do Windows de um chave=valor do -a' {
            $saida = Invoke-WinPlaybook ansible localhost -m ansible.builtin.stat -a "path=$projeto\files\dado.txt" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*"exists": true*'
        }

        It 'mantém o caminho do Windows de uma variável do inventário INI' {
            $saida = Invoke-WinPlaybook ansible -i hosts.ini meu-pc -m ansible.builtin.debug -a "msg={{ lookup('ansible.builtin.file', arquivo) }}" 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $saida
            $saida | Should-BeLikeString '*conteudo do arquivo do Windows*'
        }
    }

    Context 'quando o processo do Windows termina no meio do comando' {
        It 'encerra o comando e os processos que ele criou na distribuição' {
            $resultado = Get-SobraDeComandoInterrompido -CaminhoDoModulo $caminhoDoModulo -Distribuicao $nomeDaDistribuicao -PastaDeTrabalho $TestDrive

            $resultado.ComecouNaDistribuicao | Should-BeTrue
            $resultado.ProcessosQueSobraram | Should-Be 0
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
            InModuleScope WinPlaybook -Parameters @{ Distribuicao = $nomeDaDistribuicao } {
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = (Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao) }
            }
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
            InModuleScope WinPlaybook -Parameters @{ Distribuicao = $nomeDaDistribuicao } {
                Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = (Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao) }
            }
        }

        It 'explica como instalar de novo' {
            $mensagem = InModuleScope WinPlaybook { Get-Mensagem -Nome 'DistribuicaoNaoExisteMais' -Valores 'WinPlaybookInexistente' }

            { Invoke-WinPlaybook ansible --version 2>$null } | Should-Throw -ExceptionMessage $mensagem
        }
    }
}
