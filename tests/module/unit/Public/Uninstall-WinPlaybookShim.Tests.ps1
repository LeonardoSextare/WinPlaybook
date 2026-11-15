BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Uninstall-WinPlaybookShim' {
    BeforeAll {
        $caminhoDoModelo = Join-Path $TestDrive 'modelo.exe'
        Set-Content -LiteralPath $caminhoDoModelo -Value 'shim modelo'

        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        Mock Get-CaminhoDoModeloDeShim -ModuleName WinPlaybook { $caminhoDoModelo }
        Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Ubuntu' }
        Mock Get-RaizDeMontagemDoWsl -ModuleName WinPlaybook { '/mnt/' }
        Mock Get-ComandoDoAnsible -ModuleName WinPlaybook { 'ansible', 'ansible-playbook' }
        Mock Get-CaminhoDoPowerShell -ModuleName WinPlaybook { 'C:\PowerShell\pwsh.exe' }
        Mock Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook { }
        Mock Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook { }
    }

    BeforeEach {
        $pastaDeConfiguracao = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $pastaPadraoDosShims = Join-Path $pastaDeConfiguracao 'bin'
    }

    Context 'quando os shims estão na pasta padrão' {
        BeforeEach {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'
        }

        It 'apaga a pasta dos shims' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'tira a pasta dos shims do Path do usuário' {
            Uninstall-WinPlaybookShim

            Should-Invoke Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Pasta -eq $pastaPadraoDosShims
            }
        }

        It 'apaga a configuração e a pasta de configuração' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath $pastaDeConfiguracao | Should-BeFalse
        }
    }

    Context 'quando os shims estão numa pasta escolhida' {
        BeforeEach {
            $pastaEscolhida = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu' -Path $pastaEscolhida
        }

        It 'apaga a pasta WinPlaybook criada dentro dela' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath (Join-Path $pastaEscolhida 'WinPlaybook') | Should-BeFalse
        }

        It 'mantém a pasta escolhida' {
            Uninstall-WinPlaybookShim

            Test-Path -LiteralPath $pastaEscolhida | Should-BeTrue
        }
    }

    Context 'quando é chamado com -WhatIf' {
        BeforeEach {
            $null = Install-WinPlaybookShim -Distribution 'Ubuntu'
        }

        It 'mantém os shims' {
            Uninstall-WinPlaybookShim -WhatIf

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeTrue
        }
    }
}
