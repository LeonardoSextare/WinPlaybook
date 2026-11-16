BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Invoke-ScriptNaDistribuicao' {
    BeforeAll {
        Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $false }
    }

    Context 'quando o script termina' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 3
                $args
            }
        }

        It 'executa o script no sh, como o usuário escolhido, com os argumentos depois dele' {
            $resultado = InModuleScope WinPlaybook { Invoke-ScriptNaDistribuicao -Distribuicao 'WinPlaybook' -Script 'echo "$1"' -Argumentos 'a b' -Usuario 'root' }

            $resultado.Saida -split '\r?\n' | Should-BeCollection @('--distribution', 'WinPlaybook', '--user', 'root', '--exec', 'sh', '-c', 'echo "$1"', 'winplaybook', 'a b')
        }

        It 'devolve o código de saída do script' {
            $resultado = InModuleScope WinPlaybook { Invoke-ScriptNaDistribuicao -Distribuicao 'WinPlaybook' -Script 'exit 3' -Usuario 'root' }

            $resultado.CodigoDeSaida | Should-Be 3
        }
    }

    Context 'quando o PowerShell passa argumentos a programas na forma legada' {
        BeforeAll {
            Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $true }
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                $args
            }
        }

        It 'escapa as aspas do script' {
            $resultado = InModuleScope WinPlaybook { Invoke-ScriptNaDistribuicao -Distribuicao 'WinPlaybook' -Script 'echo "oi"' -Usuario 'root' }

            $resultado.Saida -split '\r?\n' | Should-ContainCollection 'echo \"oi\"'
        }
    }

    Context 'quando a variável WSL_UTF8 está definida' {
        BeforeAll {
            $utf8Original = $env:WSL_UTF8
            $env:WSL_UTF8 = 'original'
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                $env:WSL_UTF8
            }
        }

        AfterAll {
            $env:WSL_UTF8 = $utf8Original
        }

        It 'pede ao wsl as mensagens em UTF-8 e restaura a variável no fim' {
            $resultado = InModuleScope WinPlaybook { Invoke-ScriptNaDistribuicao -Distribuicao 'WinPlaybook' -Script 'true' -Usuario 'root' }

            "$($resultado.Saida) $env:WSL_UTF8" | Should-Be '1 original'
        }
    }
}
