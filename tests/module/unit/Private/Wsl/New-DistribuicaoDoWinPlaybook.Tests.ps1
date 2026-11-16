BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'New-DistribuicaoDoWinPlaybook' {
    Context 'quando o wsl cria a distribuição' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = 0 }
        }

        It 'instala o Debian no WSL 2, baixado da internet, com o nome e a pasta escolhidos, sem abrir a distribuição' {
            InModuleScope WinPlaybook { New-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -Pasta 'C:\WinPlaybook\distro' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args -join ' ') -eq '--install Debian --name WinPlaybook --location C:\WinPlaybook\distro --version 2 --web-download --no-launch'
            }
        }
    }

    Context 'quando o wsl não consegue criar a distribuição' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 1
                'Falha ao baixar a distribuição.'
            }
        }

        It 'explica o que conferir e mostra a resposta do wsl' {
            { InModuleScope WinPlaybook { New-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -Pasta 'C:\WinPlaybook\distro' } } | Should-Throw -ExceptionMessage '*criar a distribuição WSL WinPlaybook*internet*wsl --update*Falha ao baixar a distribuição.'
        }
    }
}
