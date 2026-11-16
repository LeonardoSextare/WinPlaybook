BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-WinPlaybookShim' {
    BeforeAll {
        $caminhoDoModelo = Join-Path $TestDrive 'modelo.exe'
        Set-Content -LiteralPath $caminhoDoModelo -Value 'shim modelo'

        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        Mock Get-CaminhoDoModeloDeShim -ModuleName WinPlaybook { $caminhoDoModelo }
        Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Ubuntu', 'Debian' }
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

    Context 'quando instala na pasta padrão' {
        It 'cria um shim para cada comando da distribuição' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            (Get-ChildItem -LiteralPath $pastaPadraoDosShims -Filter '*.ps1').BaseName | Should-BeCollection @('ansible', 'ansible-playbook')
        }

        It 'cria shims que carregam o módulo pela pasta dele' {
            $pastaDoModulo = InModuleScope WinPlaybook { Get-PastaDoModulo }

            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            Get-Content -LiteralPath (Join-Path $pastaPadraoDosShims 'ansible.ps1') | Should-BeLikeString "Import-Module '$pastaDoModulo'*"
        }

        It 'coloca a pasta dos shims no Path do usuário' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            Should-Invoke Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Pasta -eq $pastaPadraoDosShims
            }
        }

        It 'salva a pasta dos shims na configuração' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            (Get-ConfiguracaoSalva).ShimFolder | Should-Be $pastaPadraoDosShims
        }

        It 'devolve a pasta dos shims' {
            $resultado = Install-WinPlaybookShim -Distribution 'Ubuntu'

            $resultado.Folder | Should-Be $pastaPadraoDosShims
        }
    }

    Context 'quando uma distribuição é escolhida' {
        It 'cria os shims a partir dos comandos dessa distribuição' {
            $null = Install-WinPlaybookShim -Distribution 'Debian'

            Should-Invoke Get-ComandoDoAnsible -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'Debian' -and $RaizDeMontagem -eq '/mnt/'
            }
        }

        It 'salva a distribuição na configuração' {
            $null = Install-WinPlaybookShim -Distribution 'Debian'

            (Get-ConfiguracaoSalva).WslDistribution | Should-Be 'Debian'
        }

        It 'salva onde a distribuição monta as unidades do Windows' {
            $null = Install-WinPlaybookShim -Distribution 'Debian'

            (Get-ConfiguracaoSalva).WslMountRoot | Should-Be '/mnt/'
        }

        It 'devolve a distribuição' {
            $resultado = Install-WinPlaybookShim -Distribution 'Debian'

            $resultado.Distribution | Should-Be 'Debian'
        }
    }

    Context 'quando nenhuma distribuição é escolhida' {
        It 'mantém a distribuição escolhida numa instalação anterior' {
            $null = Install-WinPlaybookShim -Distribution 'Debian'

            $null = Install-WinPlaybookShim

            (Get-ConfiguracaoSalva).WslDistribution | Should-Be 'Debian'
        }

        It 'falha na primeira instalação sem criar a pasta dos shims' {
            { Install-WinPlaybookShim } | Should-Throw -ExceptionMessage '*Install-WinPlaybookShim -Distribution*'

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'mostra as distribuições instaladas na primeira instalação' {
            { Install-WinPlaybookShim } | Should-Throw -ExceptionMessage '*distribuições instaladas são: Ubuntu, Debian.'
        }
    }

    Context 'quando a distribuição escolhida não existe' {
        It 'falha sem criar a pasta dos shims' {
            { Install-WinPlaybookShim -Distribution 'Inexistente' } | Should-Throw -ExceptionMessage '*distribuição WSL Inexistente não existe*'

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'mostra as distribuições instaladas' {
            { Install-WinPlaybookShim -Distribution 'Inexistente' } | Should-Throw -ExceptionMessage '*Escolha uma das distribuições instaladas: Ubuntu, Debian.'
        }

        It 'falha também com -WhatIf' {
            { Install-WinPlaybookShim -Distribution 'Inexistente' -WhatIf } | Should-Throw -ExceptionMessage '*distribuição WSL Inexistente não existe*'
        }
    }

    Context 'quando uma pasta é escolhida' {
        It 'cria os shims numa pasta WinPlaybook dentro dela' {
            $pastaEscolhida = Join-Path $TestDrive 'ferramentas'

            $null = Install-WinPlaybookShim -Distribution 'Ubuntu' -Path $pastaEscolhida

            Test-Path -LiteralPath (Join-Path $pastaEscolhida 'WinPlaybook/bin/ansible-playbook.ps1') | Should-BeTrue
        }
    }

    Context 'quando a distribuição não tem mais um comando' {
        It 'apaga o shim desse comando' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'
            Mock Get-ComandoDoAnsible -ModuleName WinPlaybook { 'ansible' }

            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            Test-Path -LiteralPath (Join-Path $pastaPadraoDosShims 'ansible-playbook.ps1') | Should-BeFalse
        }
    }

    Context 'quando a pasta dos shims existe e não foi criada pelo WinPlaybook' {
        It 'recusa a instalação e mantém os arquivos da pasta' {
            $null = New-Item -ItemType Directory -Path $pastaPadraoDosShims -Force
            Set-Content -LiteralPath (Join-Path $pastaPadraoDosShims 'meu.txt') -Value 'meu'

            { Install-WinPlaybookShim -Distribution 'Ubuntu' } | Should-Throw -ExceptionMessage '*não foi criada pelo WinPlaybook*'

            Test-Path -LiteralPath (Join-Path $pastaPadraoDosShims 'meu.txt') | Should-BeTrue
        }
    }

    Context 'quando os shims foram instalados em outra pasta' {
        It 'apaga os shims anteriores' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            $null = Install-WinPlaybookShim -Distribution 'Ubuntu' -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString('N')))

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'tira a pasta anterior do Path do usuário' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            $null = Install-WinPlaybookShim -Distribution 'Ubuntu' -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString('N')))

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
            { Install-WinPlaybookShim -Distribution 'Ubuntu' } | Should-Throw -ExceptionMessage '*o wsl não está rodando*'

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }
    }

    Context 'quando é chamado com -WhatIf' {
        It 'não cria a pasta dos shims' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' -WhatIf

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'deixa o Path do usuário como está' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' -WhatIf

            Should-NotInvoke Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook
        }
    }

    Context 'quando uma edição do PowerShell é escolhida' {
        It 'salva essa edição para os shims executáveis' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu' -PowerShell 'Desktop'

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellDesktop
        }
    }

    Context 'quando nenhuma edição do PowerShell é escolhida' {
        It 'usa o PowerShell em execução na primeira instalação' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellAtual
        }

        It 'mantém o PowerShell escolhido numa instalação anterior' {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu' -PowerShell 'Desktop'

            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellDesktop
        }

        It 'usa o PowerShell em execução quando o salvo não existe mais' {
            $null = New-Item -ItemType Directory -Path $pastaDeConfiguracao
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Value '{ "ShimPowerShellPath": "C:\\Inexistente\\pwsh.exe" }'

            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'

            (Get-ConfiguracaoSalva).ShimPowerShellPath | Should-Be $powerShellAtual
        }
    }
}
