BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    $avisoOriginal = $env:WINPLAYBOOK_UPDATE_CHECK
}

AfterAll {
    Remove-Item -LiteralPath 'Env:WINPLAYBOOK_UPDATE_CHECK' -ErrorAction SilentlyContinue
    if ($null -ne $avisoOriginal) {
        $env:WINPLAYBOOK_UPDATE_CHECK = $avisoOriginal
    }
    Remove-Module WinPlaybook
}

Describe 'Show-AvisoDeVersaoNova' {
    BeforeEach {
        Remove-Item -LiteralPath 'Env:WINPLAYBOOK_UPDATE_CHECK' -ErrorAction SilentlyContinue
        InModuleScope WinPlaybook { Remove-Variable -Name 'versaoNovaConferida' -Scope Script -ErrorAction SilentlyContinue }
        $pastaDeConfiguracao = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $pastaDeConfiguracao
        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        Mock Start-Process -ModuleName WinPlaybook { }
        Mock Test-SaidaDeErroNoTerminal -ModuleName WinPlaybook { $true }
        $erros = [IO.StringWriter]::new()
        $errosOriginais = [Console]::Error
        [Console]::SetError($erros)
    }

    AfterEach {
        [Console]::SetError($errosOriginais)
    }

    Context 'quando a versão guardada é recente' {
        BeforeEach {
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'versao-mais-nova.json') -Value (ConvertTo-Json @{ versao = '0.20.0'; verificadoEm = (Get-Date).ToString('o') })
        }

        It 'avisa no stderr que existe uma versão mais nova, com o comando para atualizar' {
            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            $erros.ToString() | Should-BeLikeString '*versão 0.20.0 está disponível (você usa a 0.18.0)*Update-WinPlaybook*'
        }

        It 'escreve o aviso em amarelo' {
            Mock Write-LinhaColoridaNoErro -ModuleName WinPlaybook { }

            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            Should-Invoke Write-LinhaColoridaNoErro -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Cor -eq 'Yellow' -and $Texto -like '*Update-WinPlaybook*' }
        }

        It 'avisa uma vez só por sessão' {
            InModuleScope WinPlaybook {
                Show-AvisoDeVersaoNova -VersaoAtual '0.18.0'
                Show-AvisoDeVersaoNova -VersaoAtual '0.18.0'
            }

            ([regex]::Matches($erros.ToString(), 'Update-WinPlaybook')).Count | Should-Be 1
        }

        It 'não consulta a Gallery de novo' {
            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            Should-Invoke Start-Process -ModuleName WinPlaybook -Times 0 -Exactly
        }

        It 'não avisa <Descricao>' -ForEach @(
            @{ Descricao = 'quando a versão atual é a mais nova'; Versao = '0.20.0' }
            @{ Descricao = 'na versão de desenvolvimento'; Versao = '0.0.0' }
        ) {
            InModuleScope WinPlaybook -Parameters @{ Versao = $Versao } { Show-AvisoDeVersaoNova -VersaoAtual $Versao }

            $erros.ToString() | Should-Be ''
        }

        It 'não avisa com WINPLAYBOOK_UPDATE_CHECK=off' {
            $env:WINPLAYBOOK_UPDATE_CHECK = 'off'

            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            $erros.ToString() | Should-Be ''
        }

        It 'não avisa quando o stderr não é o terminal, como num programa que lê a saída' {
            Mock Test-SaidaDeErroNoTerminal -ModuleName WinPlaybook { $false }

            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            $erros.ToString() | Should-Be ''
        }
    }

    Context 'quando a versão guardada é recente, mas não é mais nova que a instalada' {
        BeforeEach {
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'versao-mais-nova.json') -Value (ConvertTo-Json @{ versao = '0.17.0'; verificadoEm = (Get-Date).ToString('o') })
        }

        It 'consulta a Gallery de novo em segundo plano' {
            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            Should-Invoke Start-Process -ModuleName WinPlaybook -Times 1 -Exactly
        }
    }

    Context 'quando a versão guardada foi consultada há mais de uma hora' {
        BeforeEach {
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'versao-mais-nova.json') -Value (ConvertTo-Json @{ versao = '0.20.0'; verificadoEm = (Get-Date).AddMinutes(-61).ToString('o') })
        }

        It 'consulta a Gallery de novo em segundo plano' {
            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            Should-Invoke Start-Process -ModuleName WinPlaybook -Times 1 -Exactly
        }

        It 'avisa com a versão guardada enquanto a consulta nova não termina' {
            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            $erros.ToString() | Should-BeLikeString '*0.20.0*'
        }
    }

    Context 'quando a versão guardada não existe' {
        It 'consulta a Gallery em segundo plano, num PowerShell novo' {
            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            Should-Invoke Start-Process -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($ArgumentList -join ' ') -like '*Update-VersaoMaisNovaGuardada*'
            }
        }

        It 'não avisa sem uma versão guardada' {
            InModuleScope WinPlaybook { Show-AvisoDeVersaoNova -VersaoAtual '0.18.0' }

            $erros.ToString() | Should-Be ''
        }
    }
}
