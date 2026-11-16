BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Initialize-DistribuicaoDoWinPlaybook' {
    BeforeAll {
        Mock wsl -ModuleName WinPlaybook { }
    }

    Context 'quando a preparação funciona' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
            InModuleScope WinPlaybook { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' }
        }

        It 'prepara a distribuição como root, para o usuário winplaybook' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'WinPlaybook' -and $Usuario -eq 'root' -and ($Argumentos -join ',') -eq 'winplaybook'
            }
        }

        It 'configura a distribuição com <Descricao>' -ForEach @(
            @{ Descricao = 'as unidades do Windows montadas com as permissões de um disco do Linux'; Trecho = 'options="metadata,umask=22,fmask=111"' }
            @{ Descricao = 'o Path do Windows fora do PATH'; Trecho = 'appendWindowsPath=false' }
            @{ Descricao = 'o systemd desligado'; Trecho = 'systemd=false' }
            @{ Descricao = 'o idioma C.UTF-8'; Trecho = 'LANG=C.UTF-8' }
        ) {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Script.Contains($Trecho) }
        }

        It 'para a distribuição, para a configuração valer no próximo comando' {
            Should-Invoke wsl -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -eq '--terminate WinPlaybook' }
        }
    }

    Context 'quando a preparação falha' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 100; Saida = 'Temporary failure resolving deb.debian.org' } }
        }

        It 'explica o que conferir e mostra a resposta da distribuição' {
            { InModuleScope WinPlaybook { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' } } | Should-Throw -ExceptionMessage '*preparar a distribuição WSL WinPlaybook*internet*Temporary failure resolving deb.debian.org'
        }

        It 'não para a distribuição' {
            { InModuleScope WinPlaybook { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' } } | Should-Throw

            Should-Invoke wsl -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }
}
