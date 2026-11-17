BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Invoke-ComandoNoWsl' {
    BeforeAll {
        $pastaDoProjeto = Join-Path $TestDrive 'projeto'
        $null = New-Item -ItemType Directory -Path (Join-Path $pastaDoProjeto 'playbooks') -Force

        Mock wsl -ModuleName WinPlaybook {
            $global:LASTEXITCODE = 0
            $args
        }
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $null; SshAgentPipe = $null } }
        Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $false }

        Push-Location $pastaDoProjeto
    }

    AfterAll {
        Pop-Location
    }

    It 'executa na distribuição escolhida na instalação' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        ($argumentosDoWsl[0..1] -join ' ') | Should-Be '--distribution Ubuntu'
    }

    It 'começa na pasta atual' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        ($argumentosDoWsl[2..3] -join ' ') | Should-Be "--cd $pastaDoProjeto"
    }

    It 'executa um login shell sem interpretar os argumentos como código de shell' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        ($argumentosDoWsl[4..6] -join ' ') | Should-Be '--exec sh -lc'
    }

    It 'passa ao script do shell a mensagem de comando ausente no idioma do usuário' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        $argumentosDoWsl[8] | Should-Be 'WinPlaybook: comando ansible-playbook ausente na distribuição WSL. Rode o Install-WinPlaybook para atualizar os comandos.'
    }

    It 'passa o comando e os argumentos dele depois da mensagem' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos '-i', 'inventory.yml', 'site.yml' }

        ($argumentosDoWsl[9..12] -join ' ') | Should-Be 'ansible-playbook -i inventory.yml site.yml'
    }

    It 'executa um comando sem argumentos' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

        ($argumentosDoWsl[9..($argumentosDoWsl.Count - 1)] -join ' ') | Should-Be 'ansible'
    }

    It 'converte os caminhos do Windows dos argumentos' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'D:\repo\site.yml' }

        $argumentosDoWsl[-1] | Should-Be '/mnt/d/repo/site.yml'
    }

    It 'converte os caminhos do disco do Linux da distribuição escolhida' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos '\\wsl.localhost\Ubuntu\home\eu\site.yml' }

        $argumentosDoWsl[-1] | Should-Be '/home/eu/site.yml'
    }

    Context 'quando a pasta atual está num drive do PowerShell' {
        BeforeAll {
            Push-Location 'TestDrive:/projeto/playbooks'
        }

        AfterAll {
            Pop-Location
        }

        It 'começa na pasta real do drive' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[3] | Should-Be (Join-Path $pastaDoProjeto 'playbooks')
        }
    }

    Context 'quando o PowerShell passa argumentos a programas na forma legada' {
        BeforeAll {
            Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $true }
        }

        It 'escapa as aspas dos argumentos' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' -Argumentos '-e', '{"a": 1}' }

            $argumentosDoWsl | Should-ContainCollection '{\"a\": 1}'
        }
    }

    Context 'quando o PowerShell passa argumentos a programas na forma moderna' {
        It 'mantém as aspas dos argumentos' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' -Argumentos '-e', '{"a": 1}' }

            $argumentosDoWsl | Should-ContainCollection '{"a": 1}'
        }
    }

    Context 'quando o comando recebe uma entrada' {
        It 'manda cada linha da entrada pelo pipeline do wsl' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos '/dev/stdin' -Entrada 'linha 1', 'linha 2', 'linha 3' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 3 -Exactly
        }
    }

    Context 'quando o comando não recebe entrada' {
        It 'chama o wsl uma vez, sem pipeline' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly
        }
    }

    Context 'quando o agente SSH do Windows está rodando e o relay está instalado' {
        BeforeAll {
            $pastaDosShims = Join-Path $TestDrive 'bin'
            $null = New-Item -ItemType File -Path (Join-Path $pastaDosShims 'exe/relay-do-agente-ssh.exe') -Force
            $relayNaDistribuicao = '/mnt/' + $pastaDosShims.Substring(0, 1).ToLowerInvariant() + $pastaDosShims.Substring(2).Replace('\', '/') + '/exe/relay-do-agente-ssh.exe'
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; SshAgentPipe = $null } }
            Mock Test-PipeDoWindows -ModuleName WinPlaybook { $true }
        }

        It 'procura o agente no pipe padrão do OpenSSH' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            Should-Invoke Test-PipeDoWindows -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Nome -eq 'openssh-ssh-agent' }
        }

        It 'passa o relay e o pipe do agente antes do comando' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            ($argumentosDoWsl[9..11] -join ' ') | Should-Be "$relayNaDistribuicao openssh-ssh-agent ansible-playbook"
        }

        It 'liga o SSH_AUTH_SOCK do comando ao relay pelo socat' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[7] | Should-BeLikeString '*export SSH_AUTH_SOCK=*socat UNIX-LISTEN:"$SSH_AUTH_SOCK"*EXEC:*relay*'
        }

        Context 'quando a configuração escolhe outro pipe para o agente' {
            BeforeAll {
                Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; SshAgentPipe = 'outro-agente' } }
            }

            It 'usa o pipe escolhido' {
                $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

                $argumentosDoWsl[10] | Should-Be 'outro-agente'
            }
        }
    }

    Context 'quando o agente SSH do Windows não está rodando' {
        BeforeAll {
            $pastaDosShims = Join-Path $TestDrive 'bin'
            $null = New-Item -ItemType File -Path (Join-Path $pastaDosShims 'exe/relay-do-agente-ssh.exe') -Force
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; SshAgentPipe = $null } }
            Mock Test-PipeDoWindows -ModuleName WinPlaybook { $false }
        }

        It 'executa o comando sem o SSH_AUTH_SOCK do WinPlaybook' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[7] | Should-NotBeLikeString '*SSH_AUTH_SOCK*'
        }

        It 'passa o comando logo depois da mensagem' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[9] | Should-Be 'ansible-playbook'
        }
    }

    Context 'quando o relay do agente SSH não está na pasta dos shims' {
        BeforeAll {
            $pastaSemRelay = Join-Path $TestDrive 'bin-sem-relay'
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaSemRelay; SshAgentPipe = $null } }
            Mock Test-PipeDoWindows -ModuleName WinPlaybook { $true }
        }

        It 'executa o comando sem o SSH_AUTH_SOCK do WinPlaybook' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[7] | Should-NotBeLikeString '*SSH_AUTH_SOCK*'
        }
    }

    Context 'quando o Windows tem uma variável ANSIBLE_' {
        BeforeAll {
            $nomeDaVariavel = "ANSIBLE_WINPLAYBOOK_TEST_$([guid]::NewGuid().ToString('N').ToUpperInvariant())"
            Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'D:\infra\ansible.cfg'
            $wslenvOriginal = $env:WSLENV
            $env:WSLENV = 'AWS_PROFILE/u'
        }

        AfterAll {
            Remove-Item -LiteralPath "Env:$nomeDaVariavel" -ErrorAction SilentlyContinue
            $env:WSLENV = $wslenvOriginal
        }

        It 'põe a variável no WSLENV, junto com as do usuário' {
            Mock wsl -ModuleName WinPlaybook { $env:WSLENV }

            $wslenvDuranteOWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $wslenvDuranteOWsl.Split(':') | Should-BeCollection @($nomeDaVariavel, 'AWS_PROFILE/u')
        }

        It 'passa o valor com o caminho convertido' {
            Mock wsl -ModuleName WinPlaybook { [Environment]::GetEnvironmentVariable($nomeDaVariavel) }

            $valorDuranteOWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $valorDuranteOWsl | Should-Be '/mnt/d/infra/ansible.cfg'
        }

        It 'restaura a variável e o WSLENV no fim' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            "$(Get-Item -LiteralPath "Env:$nomeDaVariavel" | Select-Object -ExpandProperty Value) $env:WSLENV" | Should-Be 'D:\infra\ansible.cfg AWS_PROFILE/u'
        }
    }

    Context 'quando o wsl escreve as próprias mensagens' {
        BeforeAll {
            $utf8Original = $env:WSL_UTF8
            $env:WSL_UTF8 = 'original'
            Mock wsl -ModuleName WinPlaybook { $env:WSL_UTF8 }
        }

        AfterAll {
            $env:WSL_UTF8 = $utf8Original
        }

        It 'pede ao wsl as mensagens em UTF-8' {
            $utf8DuranteOWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $utf8DuranteOWsl | Should-Be '1'
        }

        It 'restaura a variável WSL_UTF8 no fim' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $env:WSL_UTF8 | Should-Be 'original'
        }
    }

    Context 'quando o console usa a página de código do Windows' {
        BeforeAll {
            $codificacaoOriginal = [Console]::OutputEncoding
            [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(850)
            Mock wsl -ModuleName WinPlaybook { [Console]::OutputEncoding.CodePage }
        }

        AfterAll {
            [Console]::OutputEncoding = $codificacaoOriginal
        }

        It 'lê a saída do wsl em UTF-8' {
            $paginaDeCodigo = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $paginaDeCodigo | Should-Be 65001
        }

        It 'restaura a codificação do console no fim' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            [Console]::OutputEncoding.CodePage | Should-Be 850
        }
    }

    Context 'quando o wsl não encontra a distribuição do WinPlaybook' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Debian' }
        }

        It 'explica como instalar a distribuição de novo' {
            { InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } } | Should-Throw -ExceptionMessage '*distribuição WSL Ubuntu do WinPlaybook não existe mais*Install-WinPlaybook'
        }
    }

    Context 'quando o wsl falha e a distribuição existe' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'Ubuntu'
            }
        }

        It 'mantém o código de saída do wsl' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $LASTEXITCODE | Should-Be -1
        }
    }

    Context 'quando o comando falha na distribuição' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 2 }
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Ubuntu' }
        }

        It 'não consulta as distribuições de novo' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            Should-Invoke Get-DistribuicaoDoWsl -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }

    Context 'quando o WinPlaybook não foi instalado' {
        BeforeAll {
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = $null; WslMountRoot = $null; ShimFolder = $null; SshAgentPipe = $null } }
        }

        It 'explica como instalar' {
            { InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } } | Should-Throw -ExceptionMessage '*não está instalado*Install-WinPlaybook'
        }

        It 'para antes de chamar o wsl' {
            { InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } } | Should-Throw

            Should-Invoke wsl -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }

    Context 'quando o WSL não está instalado' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'wsl' } { }
        }

        It 'explica como instalar o WSL' {
            { InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } } | Should-Throw -ExceptionMessage 'O WSL não foi encontrado*wsl --install*'
        }
    }
}
