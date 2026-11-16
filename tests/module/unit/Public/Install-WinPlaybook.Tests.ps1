BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-WinPlaybook' {
    BeforeAll {
        $caminhoDoModelo = Join-Path $TestDrive 'modelo.exe'
        Set-Content -LiteralPath $caminhoDoModelo -Value 'shim modelo'

        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        Mock Get-CaminhoDoModeloDeShim -ModuleName WinPlaybook { $caminhoDoModelo }
        Mock Test-WslInstalado -ModuleName WinPlaybook { $true }
        Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Ubuntu' }
        Mock New-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Initialize-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Install-AnsibleNaDistribuicao -ModuleName WinPlaybook { }
        Mock Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Get-RaizDeMontagemDoWsl -ModuleName WinPlaybook { '/mnt/' }
        Mock Get-ComandoDoAnsible -ModuleName WinPlaybook { 'ansible', 'ansible-playbook' }
        $powerShellAtual = Join-Path $TestDrive 'atual/pwsh.exe'
        $powerShellDesktop = Join-Path $TestDrive 'desktop/powershell.exe'
        $null = New-Item -ItemType File -Path $powerShellAtual, $powerShellDesktop -Force
        Mock Get-CaminhoDoPowerShell -ModuleName WinPlaybook { $powerShellAtual }
        Mock Get-CaminhoDoPowerShell -ModuleName WinPlaybook -ParameterFilter { $Edicao -eq 'Desktop' } { $powerShellDesktop }

        Mock Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook { }
        Mock Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook { }

        function Get-ConfiguracaoSalva {
            <#
            .SYNOPSIS
            Devolve o settings.json que a instalação gravou na pasta de configuração do teste.

            .EXAMPLE
            (Get-ConfiguracaoSalva).ShimFolder
            #>
            [CmdletBinding()]
            [OutputType([pscustomobject])]
            param()

            return Get-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Raw | ConvertFrom-Json
        }
    }

    BeforeEach {
        $pastaDeConfiguracao = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $pastaPadraoDosShims = Join-Path $pastaDeConfiguracao 'bin'
    }

    Context 'quando instala pela primeira vez' {
        It 'cria a distribuição WinPlaybook na pasta do WinPlaybook' {
            $null = Install-WinPlaybook

            Should-Invoke New-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Nome -eq 'WinPlaybook' -and $Pasta -eq (Join-Path $pastaDeConfiguracao 'distro')
            }
        }

        It 'prepara a distribuição com a pasta .ssh do usuário' {
            $null = Install-WinPlaybook

            Should-Invoke Initialize-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Nome -eq 'WinPlaybook' -and $PastaDoSsh -eq (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.ssh')
            }
        }

        It 'instala o Ansible mais novo, sem pacotes Python extras' {
            $null = Install-WinPlaybook

            Should-Invoke Install-AnsibleNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Nome -eq 'WinPlaybook' -and $VersaoDoAnsible -eq '' -and @($PacotesPython).Count -eq 0
            }
        }

        It 'cria um shim para cada comando da distribuição' {
            $null = Install-WinPlaybook

            (Get-ChildItem -LiteralPath $pastaPadraoDosShims -Filter '*.ps1').BaseName | Should-BeCollection @('ansible', 'ansible-playbook')
        }

        It 'cria shims que carregam o módulo pela pasta dele' {
            $pastaDoModulo = InModuleScope WinPlaybook { Get-PastaDoModulo }

            $null = Install-WinPlaybook

            Get-Content -LiteralPath (Join-Path $pastaPadraoDosShims 'ansible.ps1') | Should-BeLikeString "Import-Module '$pastaDoModulo'*"
        }

        It 'coloca a pasta dos shims no Path do usuário' {
            $null = Install-WinPlaybook

            Should-Invoke Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Pasta -eq $pastaPadraoDosShims
            }
        }

        It 'salva a pasta dos shims, a distribuição e a raiz de montagem na configuração' {
            $null = Install-WinPlaybook

            $configuracao = Get-ConfiguracaoSalva
            "$($configuracao.ShimFolder)|$($configuracao.WslDistribution)|$($configuracao.WslMountRoot)" | Should-Be "$pastaPadraoDosShims|WinPlaybook|/mnt/"
        }

        It 'devolve a pasta dos shims, a distribuição e os comandos' {
            $resultado = Install-WinPlaybook

            "$($resultado.Folder)|$($resultado.Distribution)|$($resultado.Commands -join ',')" | Should-Be "$pastaPadraoDosShims|WinPlaybook|ansible,ansible-playbook"
        }
    }

    Context 'quando a distribuição do WinPlaybook já existe' {
        BeforeAll {
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Ubuntu', 'WinPlaybook' }
        }

        It 'não cria a distribuição de novo' {
            $null = Install-WinPlaybook

            Should-Invoke New-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
        }

        It 'prepara a distribuição e instala o Ansible de novo' {
            $null = Install-WinPlaybook

            Should-Invoke Install-AnsibleNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly
        }
    }

    Context 'quando a versão do Ansible e os pacotes Python são escolhidos' {
        It 'instala a versão e os pacotes escolhidos' {
            $null = Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3', 'netaddr'

            Should-Invoke Install-AnsibleNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $VersaoDoAnsible -eq '12.*' -and ($PacotesPython -join ',') -eq 'boto3,netaddr'
            }
        }

        It 'mantém a versão e os pacotes na instalação seguinte' {
            $null = Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3'

            $null = Install-WinPlaybook

            Should-Invoke Install-AnsibleNaDistribuicao -ModuleName WinPlaybook -Times 2 -Exactly -ParameterFilter {
                $VersaoDoAnsible -eq '12.*' -and ($PacotesPython -join ',') -eq 'boto3'
            }
        }

        It 'volta para o Ansible mais novo e sem pacotes extras com valores vazios' {
            $null = Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3'

            $null = Install-WinPlaybook -AnsibleVersion '' -PythonPackage @()

            Should-Invoke Install-AnsibleNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $VersaoDoAnsible -eq '' -and @($PacotesPython).Count -eq 0
            }
        }
    }

    Context 'quando o WSL não está instalado' {
        BeforeAll {
            Mock Test-WslInstalado -ModuleName WinPlaybook { $false }
        }

        It 'explica como instalar o WSL' {
            { Install-WinPlaybook } | Should-Throw -ExceptionMessage 'O WSL não está instalado*wsl --install --no-distribution*'
        }

        It 'falha sem criar a distribuição nem a pasta dos shims' {
            { Install-WinPlaybook } | Should-Throw

            Should-Invoke New-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }
    }

    Context 'quando a instalação do Ansible falha' {
        BeforeAll {
            Mock Install-AnsibleNaDistribuicao -ModuleName WinPlaybook { throw 'sem internet' }
        }

        It 'falha sem criar a pasta dos shims nem mudar o Path' {
            { Install-WinPlaybook } | Should-Throw -ExceptionMessage '*sem internet*'

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
            Should-NotInvoke Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook
        }

        It 'apaga a distribuição que acabou de criar' {
            { Install-WinPlaybook } | Should-Throw -ExceptionMessage '*sem internet*'

            Should-Invoke Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Nome -eq 'WinPlaybook' -and $Pasta -eq (Join-Path $pastaDeConfiguracao 'distro')
            }
        }

        Context 'quando a distribuição já existia' {
            BeforeAll {
                Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'WinPlaybook' }
            }

            It 'mantém a distribuição' {
                { Install-WinPlaybook } | Should-Throw -ExceptionMessage '*sem internet*'

                Should-NotInvoke Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook
            }
        }
    }

    Context 'quando uma pasta é escolhida' {
        It 'cria os shims numa pasta WinPlaybook dentro dela' {
            $pastaEscolhida = Join-Path $TestDrive 'ferramentas'

            $null = Install-WinPlaybook -Path $pastaEscolhida

            Test-Path -LiteralPath (Join-Path $pastaEscolhida 'WinPlaybook/bin/ansible-playbook.ps1') | Should-BeTrue
        }
    }

    Context 'quando a distribuição não tem mais um comando' {
        It 'apaga o shim desse comando' {
            $null = Install-WinPlaybook
            Mock Get-ComandoDoAnsible -ModuleName WinPlaybook { 'ansible' }

            $null = Install-WinPlaybook

            Test-Path -LiteralPath (Join-Path $pastaPadraoDosShims 'ansible-playbook.ps1') | Should-BeFalse
        }
    }

    Context 'quando a pasta dos shims existe e não foi criada pelo WinPlaybook' {
        It 'recusa a instalação e mantém os arquivos da pasta' {
            $null = New-Item -ItemType Directory -Path $pastaPadraoDosShims -Force
            Set-Content -LiteralPath (Join-Path $pastaPadraoDosShims 'meu.txt') -Value 'meu'

            { Install-WinPlaybook } | Should-Throw -ExceptionMessage '*não foi criada pelo WinPlaybook*'

            Test-Path -LiteralPath (Join-Path $pastaPadraoDosShims 'meu.txt') | Should-BeTrue
        }
    }

    Context 'quando os shims foram instalados em outra pasta' {
        It 'apaga os shims anteriores' {
            $null = Install-WinPlaybook

            $null = Install-WinPlaybook -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString('N')))

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'tira a pasta anterior do Path do usuário' {
            $null = Install-WinPlaybook

            $null = Install-WinPlaybook -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString('N')))

            Should-Invoke Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Pasta -eq $pastaPadraoDosShims
            }
        }
    }

    Context 'quando os comandos da distribuição não podem ser listados' {
        BeforeAll {
            Mock Get-ComandoDoAnsible -ModuleName WinPlaybook { throw 'o wsl não está rodando' }
        }

        It 'falha sem criar a pasta dos shims' {
            { Install-WinPlaybook } | Should-Throw -ExceptionMessage '*o wsl não está rodando*'

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }
    }

    Context 'quando é chamado com -WhatIf' {
        It 'não cria nem prepara a distribuição' {
            Install-WinPlaybook -WhatIf

            Should-Invoke New-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
            Should-Invoke Initialize-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
        }

        It 'não cria a pasta dos shims' {
            Install-WinPlaybook -WhatIf

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'deixa o Path do usuário como está' {
            Install-WinPlaybook -WhatIf

            Should-NotInvoke Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook
        }
    }

    Context 'quando uma edição do PowerShell é escolhida' {
        It 'salva essa edição para os shims executáveis' {
            $null = Install-WinPlaybook -PowerShell 'Desktop'

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellDesktop
        }
    }

    Context 'quando nenhuma edição do PowerShell é escolhida' {
        It 'usa o PowerShell em execução na primeira instalação' {
            $null = Install-WinPlaybook

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellAtual
        }

        It 'mantém o PowerShell escolhido numa instalação anterior' {
            $null = Install-WinPlaybook -PowerShell 'Desktop'

            $null = Install-WinPlaybook

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellDesktop
        }

        It 'usa o PowerShell em execução quando o salvo não existe mais' {
            $null = New-Item -ItemType Directory -Path $pastaDeConfiguracao
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Value '{ "ShimPowerShellPath": "C:\\Inexistente\\pwsh.exe" }'

            $null = Install-WinPlaybook

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellAtual
        }
    }
}
