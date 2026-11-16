BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
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
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'Ubuntu'; WslMountRoot = '/mnt/' } }
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

    It 'passa a raiz de montagem, o comando e os argumentos dele ao script do shell' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos '-i', 'inventory.yml', 'site.yml' }

        ($argumentosDoWsl[8..12] -join ' ') | Should-Be '/mnt/ ansible-playbook -i inventory.yml site.yml'
    }

    It 'executa um comando sem argumentos' {
        $argumentosDoWsl = InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' }

        ($argumentosDoWsl[8..($argumentosDoWsl.Count - 1)] -join ' ') | Should-Be '/mnt/ ansible'
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

    Context 'quando o wsl não encontra a distribuição escolhida na instalação' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Debian' }
        }

        It 'explica como escolher outra distribuição' {
            { InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } } | Should-Throw -ExceptionMessage '*distribuição WSL Ubuntu*não existe mais*Install-WinPlaybookShim -Distribution*'
        }
    }

    Context 'quando o wsl falha e a distribuição escolhida existe' {
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

    Context 'quando nenhuma distribuição foi escolhida' {
        BeforeAll {
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = $null; WslMountRoot = $null } }
        }

        It 'explica como escolher uma' {
            { InModuleScope WinPlaybook { Invoke-ComandoNoWsl -Comando 'ansible' } } | Should-Throw -ExceptionMessage '*Install-WinPlaybookShim -Distribution*'
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
