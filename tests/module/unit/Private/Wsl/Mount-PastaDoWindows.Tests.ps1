BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Mount-PastaDoWindows' {
    BeforeAll {
        $montagens = @(
            [pscustomobject]@{ Origem = 'W:'; PontoDeMontagem = '/mnt/w' }
            [pscustomobject]@{ Origem = '\\servidor\infra'; PontoDeMontagem = '/mnt/unc/servidor/infra' }
        )
    }

    Context 'quando a distribuição monta as pastas' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
        }

        It 'monta como root, com o drvfs e as permissões das unidades do WSL' {
            InModuleScope WinPlaybook -Parameters @{ Montagens = $montagens } { Mount-PastaDoWindows -Distribuicao 'WinPlaybook' -Montagem $Montagens }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'WinPlaybook' -and $Usuario -eq 'root' -and $Script.Contains('mount -t drvfs') -and $Script.Contains('umask=22,fmask=111')
            }
        }

        It 'passa cada origem seguida do ponto de montagem, depois do dono' {
            InModuleScope WinPlaybook -Parameters @{ Montagens = $montagens } { Mount-PastaDoWindows -Distribuicao 'WinPlaybook' -Montagem $Montagens }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($Argumentos -join '|') -eq 'winplaybook|W:|/mnt/w|\\servidor\infra|/mnt/unc/servidor/infra'
            }
        }

        It 'não monta de novo uma pasta já montada' {
            InModuleScope WinPlaybook -Parameters @{ Montagens = $montagens } { Mount-PastaDoWindows -Distribuicao 'WinPlaybook' -Montagem $Montagens }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Script.Contains('mountpoint -q "$ponto_de_montagem" && continue') }
        }
    }

    Context 'quando a montagem falha' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 1; Saida = 'special device does not exist' } }
        }

        It 'explica o que não foi acessado e o que a distribuição respondeu' {
            { InModuleScope WinPlaybook -Parameters @{ Montagens = $montagens } { Mount-PastaDoWindows -Distribuicao 'WinPlaybook' -Montagem $Montagens } } |
                Should-Throw -ExceptionMessage '*W:, \\servidor\infra*special device does not exist*'
        }
    }
}
