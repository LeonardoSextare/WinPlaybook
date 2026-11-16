BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Remove-DistribuicaoDoWinPlaybook' {
    BeforeAll {
        Mock Remove-PastaVazia -ModuleName WinPlaybook { }
    }

    Context 'quando a distribuição existe' {
        BeforeAll {
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Ubuntu', 'WinPlaybook' }
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 0 }
            InModuleScope WinPlaybook { Remove-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -Pasta 'C:\WinPlaybook\distro' }
        }

        It 'apaga a distribuição no WSL' {
            Should-Invoke wsl -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -eq '--unregister WinPlaybook' }
        }

        It 'apaga a pasta do disco quando ela fica vazia' {
            Should-Invoke Remove-PastaVazia -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Pasta -eq 'C:\WinPlaybook\distro' }
        }
    }

    Context 'quando a distribuição não existe mais' {
        BeforeAll {
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'Ubuntu' }
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 0 }
        }

        It 'termina sem erro e sem chamar o wsl' {
            InModuleScope WinPlaybook { Remove-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -Pasta 'C:\WinPlaybook\distro' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }

    Context 'quando o wsl não consegue apagar a distribuição' {
        BeforeAll {
            Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'WinPlaybook' }
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 1
                'O arquivo está em uso.'
            }
        }

        It 'mostra a resposta do wsl' {
            { InModuleScope WinPlaybook { Remove-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -Pasta 'C:\WinPlaybook\distro' } } | Should-Throw -ExceptionMessage '*apagar a distribuição WSL WinPlaybook*O arquivo está em uso.'
        }
    }
}
