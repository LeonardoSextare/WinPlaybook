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
        $pastaDoProjetoNaDistribuicao = '/mnt/' + $pastaDoProjeto.Substring(0, 1).ToLowerInvariant() + $pastaDoProjeto.Substring(2).Replace('\', '/')

        Mock wsl -ModuleName WinPlaybook {
            $global:LASTEXITCODE = 0
            $args
        }
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $null; ShimPowerShellPath = $null; SshAgentPipe = $null } }
        Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $false }
        Mock Get-DestinoDeUnidade -ModuleName WinPlaybook { @{} }
        Mock Get-CaminhoDoSupervisor -ModuleName WinPlaybook { 'C:\Temp\WinPlaybook\supervisor-teste.py' }
        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { Join-Path $TestDrive 'configuracao' }
        Mock Get-CaminhoDosCertificadosDoWindows -ModuleName WinPlaybook { 'C:\Temp\WinPlaybook\certificados-teste.pem' }
        Mock Mount-PastaDoWindows -ModuleName WinPlaybook { }

        Push-Location $pastaDoProjeto
    }

    AfterAll {
        Pop-Location
    }

    It 'não monta nada quando os caminhos estão em unidades que o WSL monta sozinho' {
        $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'D:\repo\site.yml' }

        Should-NotInvoke Mount-PastaDoWindows -ModuleName WinPlaybook
    }

    Context 'quando um argumento está numa unidade do subst ou de rede' {
        BeforeAll {
            Mock Get-DestinoDeUnidade -ModuleName WinPlaybook { @{ W = 'C:\infra'; Z = '\\servidor\infra\projetos' } }
        }

        It 'passa o caminho da pasta real da unidade do subst' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'W:\site.yml' }

            $argumentosDoWsl[-1] | Should-Be '/mnt/c/infra/site.yml'
            Should-NotInvoke Mount-PastaDoWindows -ModuleName WinPlaybook
        }

        It 'monta o compartilhamento da unidade de rede e passa o caminho dele' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'Z:\site.yml' }

            $argumentosDoWsl[-1] | Should-Be '/mnt/unc/servidor/infra/projetos/site.yml'
            Should-Invoke Mount-PastaDoWindows -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'Ubuntu' -and $Montagem.Count -eq 1 -and $Montagem[0].Origem -eq '\\servidor\infra'
            }
        }
    }

    Context 'quando um argumento está num compartilhamento de rede' {
        It 'monta o compartilhamento na distribuição e passa o caminho dele' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos '\\servidor\infra\site.yml' }

            $argumentosDoWsl[-1] | Should-Be '/mnt/unc/servidor/infra/site.yml'
            Should-Invoke Mount-PastaDoWindows -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Montagem[0].Origem -eq '\\servidor\infra' -and $Montagem[0].PontoDeMontagem -eq '/mnt/unc/servidor/infra'
            }
        }
    }

    It 'executa na distribuição escolhida na instalação' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        ($argumentosDoWsl[0..1] -join ' ') | Should-Be '--distribution Ubuntu'
    }

    It 'começa na pasta atual' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        ($argumentosDoWsl[2..3] -join ' ') | Should-Be "--cd $pastaDoProjetoNaDistribuicao"
    }

    It 'executa um login shell sem interpretar os argumentos como código de shell' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        ($argumentosDoWsl[4..6] -join ' ') | Should-Be '--exec sh -lc'
    }

    It 'passa ao script do shell a mensagem de comando ausente no idioma do usuário' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        $argumentosDoWsl[8] | Should-Be 'WinPlaybook: comando ansible-playbook ausente na distribuição WSL. Rode o Install-WinPlaybook para atualizar os comandos.'
    }

    It 'passa, depois da mensagem, o caminho na distribuição do supervisor que encerra o comando junto com o Windows' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        $argumentosDoWsl[9] | Should-Be '/mnt/c/Temp/WinPlaybook/supervisor-teste.py'
    }

    It 'mantém a linha de comando curta com um ambiente grande' {
        $nomeGrande = "WINPLAYBOOK_TEST_$([guid]::NewGuid().ToString('N'))"
        Set-Item -LiteralPath "Env:$nomeGrande" -Value ('x' * 20000)
        try {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }
        }
        finally {
            Remove-Item -LiteralPath "Env:$nomeGrande"
        }

        ($argumentosDoWsl -join ' ').Length | Should-BeLessThan 8000
    }

    It 'executa o comando pelo python3 do sistema, com o supervisor' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

        $argumentosDoWsl[7] | Should-BeLikeString '*exec /usr/bin/python3 "$supervisor" "$@"'
    }

    It 'passa o comando e os argumentos dele depois do supervisor' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos '-i', 'inventory.yml', 'site.yml' }

        ($argumentosDoWsl[10..13] -join ' ') | Should-Be 'ansible-playbook -i inventory.yml site.yml'
    }

    It 'executa um comando sem argumentos' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

        ($argumentosDoWsl[10..($argumentosDoWsl.Count - 1)] -join ' ') | Should-Be 'ansible'
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

            $argumentosDoWsl[3] | Should-Be "$pastaDoProjetoNaDistribuicao/playbooks"
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
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; ShimPowerShellPath = $null; SshAgentPipe = $null } }
            Mock Test-PipeDoWindows -ModuleName WinPlaybook { $true }
        }

        It 'procura o agente no pipe padrão do OpenSSH' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            Should-Invoke Test-PipeDoWindows -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Nome -eq 'openssh-ssh-agent' }
        }

        It 'passa o relay e o pipe do agente antes do comando' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            ($argumentosDoWsl[10..12] -join ' ') | Should-Be "$relayNaDistribuicao openssh-ssh-agent ansible-playbook"
        }

        It 'liga o SSH_AUTH_SOCK do comando ao relay pelo socat' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[7] | Should-BeLikeString '*export SSH_AUTH_SOCK=*socat UNIX-LISTEN:"$SSH_AUTH_SOCK"*EXEC:*relay*'
        }

        Context 'quando a configuração escolhe outro pipe para o agente' {
            BeforeAll {
                Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; ShimPowerShellPath = $null; SshAgentPipe = 'outro-agente' } }
            }

            It 'usa o pipe escolhido' {
                $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

                $argumentosDoWsl[11] | Should-Be 'outro-agente'
            }
        }
    }

    Context 'quando o agente SSH do Windows não está rodando' {
        BeforeAll {
            $pastaDosShims = Join-Path $TestDrive 'bin'
            $null = New-Item -ItemType File -Path (Join-Path $pastaDosShims 'exe/relay-do-agente-ssh.exe') -Force
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; ShimPowerShellPath = $null; SshAgentPipe = $null } }
            Mock Test-PipeDoWindows -ModuleName WinPlaybook { $false }
        }

        It 'executa o comando sem o SSH_AUTH_SOCK do WinPlaybook' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[7] | Should-NotBeLikeString '*SSH_AUTH_SOCK*'
        }

        It 'passa o comando logo depois da mensagem' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[10] | Should-Be 'ansible-playbook'
        }
    }

    Context 'quando o relay do agente SSH não está na pasta dos shims' {
        BeforeAll {
            $pastaSemRelay = Join-Path $TestDrive 'bin-sem-relay'
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaSemRelay; ShimPowerShellPath = $null; SshAgentPipe = $null } }
            Mock Test-PipeDoWindows -ModuleName WinPlaybook { $true }
        }

        It 'executa o comando sem o SSH_AUTH_SOCK do WinPlaybook' {
            $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $argumentosDoWsl[7] | Should-NotBeLikeString '*SSH_AUTH_SOCK*'
        }
    }

    Context 'quando o Path do Windows tem a pasta dos shims' {
        BeforeAll {
            $pastaDosShims = Join-Path $TestDrive 'bin-dos-shims'
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; ShimPowerShellPath = $null; SshAgentPipe = $null } }
            $pathOriginal = $env:Path
            $env:Path = "C:\Ferramentas;$pastaDosShims;D:\Outras\"
        }

        AfterAll {
            $env:Path = $pathOriginal
        }

        It 'passa ao supervisor as outras pastas, na montagem com execução' {
            Mock wsl -ModuleName WinPlaybook { $env:WINPLAYBOOK_ENVIRONMENT }

            $ambiente = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } | ConvertFrom-Json
            @($ambiente.pathDoWindows) | Should-BeCollection @('/opt/winplaybook/exec/c/Ferramentas', '/opt/winplaybook/exec/d/Outras')
        }
    }

    Context 'quando a pasta dos shims tem o relay de rede' {
        BeforeAll {
            $pastaDosShims = Join-Path $TestDrive 'bin-com-relay-de-rede'
            $null = New-Item -ItemType File -Path (Join-Path $pastaDosShims 'exe\relay-de-rede.exe') -Force
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; ShimPowerShellPath = $null; SshAgentPipe = $null } }
            Mock Get-CaminhoDoRelayDoAgenteSsh -ModuleName WinPlaybook { Join-Path $TestDrive 'sem-relay-do-agente.exe' }
        }

        It 'passa ao supervisor o relay de rede, pela unidade montada' {
            Mock wsl -ModuleName WinPlaybook { $env:WINPLAYBOOK_ENVIRONMENT }
            $esperado = '/mnt/' + $pastaDosShims.Substring(0, 1).ToLowerInvariant() + $pastaDosShims.Substring(2).Replace('\', '/') + '/exe/relay-de-rede.exe'

            $ambiente = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } | ConvertFrom-Json

            $ambiente.relayDeRede | Should-Be $esperado
        }
    }

    It 'não passa o relay de rede sem a pasta dos shims' {
        Mock wsl -ModuleName WinPlaybook { $env:WINPLAYBOOK_ENVIRONMENT }

        $ambiente = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } | ConvertFrom-Json

        $ambiente.PSObject.Properties.Name | Should-NotContainCollection 'relayDeRede'
    }

    Context 'quando o WinPlaybook está instalado com shims' {
        BeforeAll {
            $pastaDosShims = Join-Path $TestDrive 'bin-dos-comandos-do-projeto'
            $null = New-Item -ItemType Directory -Path $pastaDosShims -Force
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/'; ShimFolder = $pastaDosShims; ShimPowerShellPath = 'C:\PowerShell\pwsh.exe'; SshAgentPipe = $null } }
            Mock Get-CaminhoDoRelayDoAgenteSsh -ModuleName WinPlaybook { Join-Path $TestDrive 'sem-relay-do-agente.exe' }
            Mock Add-ShimDeComandoDoProjeto -ModuleName WinPlaybook { }
        }

        It 'pede ao supervisor a lista dos comandos do projeto, na pasta do supervisor' {
            Mock wsl -ModuleName WinPlaybook { $env:WINPLAYBOOK_ENVIRONMENT }

            $ambiente = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } | ConvertFrom-Json

            $ambiente.comandosDoProjeto | Should-BeLikeString '/mnt/c/Temp/WinPlaybook/comandos-do-projeto-*.txt'
        }

        It 'cria os shims dos comandos do projeto depois do comando, sem mudar o código de saída' {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 3 }

            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $LASTEXITCODE | Should-Be 3
            Should-Invoke Add-ShimDeComandoDoProjeto -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $CaminhoDaLista -like 'C:\Temp\WinPlaybook\comandos-do-projeto-*.txt' -and $PastaDosShims -eq $pastaDosShims -and $CaminhoDoPowerShell -eq 'C:\PowerShell\pwsh.exe'
            }
        }
    }

    It 'passa ao supervisor o arquivo dos certificados raiz do Windows, pela unidade montada' {
        Mock wsl -ModuleName WinPlaybook { $env:WINPLAYBOOK_ENVIRONMENT }

        $ambiente = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } | ConvertFrom-Json

        $ambiente.certificadosDoWindows | Should-Be '/mnt/c/Temp/WinPlaybook/certificados-teste.pem'
    }

    Context 'quando o Windows tem uma variável de ambiente' {
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

        It 'passa a variável ao supervisor, pelo WINPLAYBOOK_ENVIRONMENT do WSLENV, com o caminho convertido' {
            Mock wsl -ModuleName WinPlaybook { if ($env:WSLENV.Split(':') -contains 'WINPLAYBOOK_ENVIRONMENT') { $env:WINPLAYBOOK_ENVIRONMENT } }

            $ambiente = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } | ConvertFrom-Json
            $ambiente.variaveis.$nomeDaVariavel | Should-Be '/mnt/d/infra/ansible.cfg'
        }

        It 'mantém a variável do Windows como estava durante o comando' {
            Mock wsl -ModuleName WinPlaybook { [Environment]::GetEnvironmentVariable($nomeDaVariavel) }

            $valorDuranteOWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            $valorDuranteOWsl | Should-Be 'D:\infra\ansible.cfg'
        }

        It 'restaura o WSLENV e tira o WINPLAYBOOK_ENVIRONMENT no fim' {
            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            "$env:WSLENV|$env:WINPLAYBOOK_ENVIRONMENT" | Should-Be 'AWS_PROFILE/u|'
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
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = $null; WslMountRoot = $null; ShimFolder = $null; ShimPowerShellPath = $null; SshAgentPipe = $null } }
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

    Context 'quando grava o log' {
        BeforeEach {
            $nivelOriginal = $env:WINPLAYBOOK_LOG
            Remove-Item -LiteralPath (Join-Path $TestDrive 'configuracao\logs') -Recurse -Force -ErrorAction SilentlyContinue
        }

        AfterEach {
            Remove-Item -LiteralPath 'Env:WINPLAYBOOK_LOG' -ErrorAction SilentlyContinue
            if ($null -ne $nivelOriginal) {
                $env:WINPLAYBOOK_LOG = $nivelOriginal
            }
        }

        It 'registra o comando, o código de saída e os tempos' {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 4 }

            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml' }

            $log = Get-Content -LiteralPath (InModuleScope WinPlaybook { Get-CaminhoDoLog }) -Raw -Encoding UTF8
            $log | Should-BeLikeString '*`[INFO`]*ansible-playbook saiu com 4 em * ms (preparação no Windows: * ms, distribuição: * ms)*'
        }

        It 'não registra os argumentos fora do nível debug' {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 0 }

            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'segredo.yml' }

            Get-Content -LiteralPath (InModuleScope WinPlaybook { Get-CaminhoDoLog }) -Raw -Encoding UTF8 | Should-NotBeLikeString '*segredo.yml*'
        }

        It 'passa ao supervisor o log, no nível debug' {
            $env:WINPLAYBOOK_LOG = 'debug'
            Mock wsl -ModuleName WinPlaybook { $env:WINPLAYBOOK_ENVIRONMENT }

            $ambiente = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } | ConvertFrom-Json

            $ambiente.log | Should-BeLikeString '/mnt/*/configuracao/logs/winplaybook-*.log'
        }

        It 'não grava nada no nível off' {
            $env:WINPLAYBOOK_LOG = 'off'
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 0 }

            $null = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

            Test-Path -LiteralPath (Join-Path $TestDrive 'configuracao\logs') | Should-BeFalse
        }
    }
}
