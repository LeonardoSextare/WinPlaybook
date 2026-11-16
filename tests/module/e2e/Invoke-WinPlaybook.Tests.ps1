BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

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
