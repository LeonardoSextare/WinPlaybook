BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Uninstall-WinPlaybook' {
    BeforeAll {
        $caminhoDoModelo = Join-Path $TestDrive 'modelo.exe'
        Set-Content -LiteralPath $caminhoDoModelo -Value 'shim modelo'

        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        Mock Get-CaminhoDoModeloDeShim -ModuleName WinPlaybook { $caminhoDoModelo }
        Mock Test-WslInstalado -ModuleName WinPlaybook { $true }
        Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'WinPlaybook' }
        Mock Initialize-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Install-AnsibleNaDistribuicao -ModuleName WinPlaybook { }
        Mock Get-RaizDeMontagemDoWsl -ModuleName WinPlaybook { '/mnt/' }
        Mock Get-ComandoDoAnsible -ModuleName WinPlaybook { 'ansible', 'ansible-playbook' }
        Mock Get-CaminhoDoPowerShell -ModuleName WinPlaybook { 'C:\PowerShell\pwsh.exe' }
        Mock Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook { }
        Mock Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook { }
        Mock Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { }
    }

    BeforeEach {
        $pastaDeConfiguracao = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $pastaPadraoDosShims = Join-Path $pastaDeConfiguracao 'bin'
    }

    Context 'quando o WinPlaybook está instalado na pasta padrão' {
        BeforeEach {
            $null = Install-WinPlaybook
        }

        It 'apaga a distribuição WinPlaybook e a pasta do disco dela' {
            Uninstall-WinPlaybook -Confirm:$false

            Should-Invoke Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Nome -eq 'WinPlaybook' -and $Pasta -eq (Join-Path $pastaDeConfiguracao 'distro')
            }
        }

        It 'apaga a pasta dos shims' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'tira a pasta dos shims do Path do usuário' {
            Uninstall-WinPlaybook -Confirm:$false

            Should-Invoke Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Pasta -eq $pastaPadraoDosShims
            }
        }

        It 'apaga a configuração e a pasta de configuração' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaDeConfiguracao | Should-BeFalse
        }
    }

    Context 'quando os shims estão numa pasta escolhida' {
        BeforeEach {
            $pastaEscolhida = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = Install-WinPlaybook -Path $pastaEscolhida
        }

        It 'apaga a pasta WinPlaybook criada dentro dela' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath (Join-Path $pastaEscolhida 'WinPlaybook') | Should-BeFalse
        }

        It 'mantém a pasta escolhida' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaEscolhida | Should-BeTrue
        }
    }

    Context 'quando apagar a distribuição falha' {
        BeforeEach {
            $null = Install-WinPlaybook
            Mock Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { throw 'a distribuição está em uso' }
        }

        It 'falha e mantém os shims' {
            { Uninstall-WinPlaybook -Confirm:$false } | Should-Throw -ExceptionMessage '*em uso*'

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeTrue
        }
    }

    Context 'quando é chamado com -WhatIf' {
        BeforeEach {
            $null = Install-WinPlaybook
        }

        It 'mantém a distribuição e os shims' {
            Uninstall-WinPlaybook -WhatIf

            Should-Invoke Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeTrue
        }
    }

    Context 'quando o comando é chamado' {
        It 'pede confirmação antes de apagar a distribuição' {
            $impacto = (Get-Command Uninstall-WinPlaybook).ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } | ForEach-Object { $_.ConfirmImpact }

            "$impacto" | Should-Be 'High'
        }
    }
}
