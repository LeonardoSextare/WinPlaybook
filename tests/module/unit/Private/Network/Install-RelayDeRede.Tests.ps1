BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-RelayDeRede' {
    BeforeAll {
        $caminhoDoExecutavel = Join-Path $TestDrive 'compilado/relay-de-rede.exe'
        $null = New-Item -ItemType File -Path $caminhoDoExecutavel -Value 'relay compilado' -Force
        $pastaDosShims = Join-Path $TestDrive 'bin'
        $parametros = @{
            CaminhoDoExecutavel = $caminhoDoExecutavel
            PastaDosShims       = $pastaDosShims
        }
    }

    Context 'quando a distribuição aceita o chmod' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
            InModuleScope WinPlaybook -Parameters $parametros { Install-RelayDeRede -CaminhoDoExecutavel $CaminhoDoExecutavel -PastaDosShims $PastaDosShims -Distribuicao 'WinPlaybook' -RaizDeMontagem '/mnt/' }
        }

        It 'copia o relay para a subpasta exe da pasta dos shims' {
            Get-Content -LiteralPath (Join-Path $pastaDosShims 'exe/relay-de-rede.exe') | Should-Be 'relay compilado'
        }

        It 'dá permissão de execução ao relay, pelo caminho dele na distribuição' {
            $caminhoNaDistribuicao = '/mnt/' + $pastaDosShims.Substring(0, 1).ToLowerInvariant() + $pastaDosShims.Substring(2).Replace('\', '/') + '/exe/relay-de-rede.exe'

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'WinPlaybook' -and $Script.Contains('chmod +x') -and $Argumentos[0] -eq $caminhoNaDistribuicao
            }
        }
    }

    Context 'quando a distribuição recusa o chmod' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 1; Saida = 'Operation not permitted' } }
        }

        It 'explica o que fazer e mostra a resposta da distribuição' {
            { InModuleScope WinPlaybook -Parameters $parametros { Install-RelayDeRede -CaminhoDoExecutavel $CaminhoDoExecutavel -PastaDosShims $PastaDosShims -Distribuicao 'WinPlaybook' -RaizDeMontagem '/mnt/' } } | Should-Throw -ExceptionMessage '*relay de rede*Install-WinPlaybook*Operation not permitted'
        }
    }
}
