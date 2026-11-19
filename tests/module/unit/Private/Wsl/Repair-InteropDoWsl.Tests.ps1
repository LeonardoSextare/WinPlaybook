BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Repair-InteropDoWsl' {
    BeforeEach {
        Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
        Mock Write-Log -ModuleName WinPlaybook { }
    }

    Context 'quando o interop do WSL está registrado' {
        BeforeEach {
            Mock Test-Path -ModuleName WinPlaybook { $true } -ParameterFilter { $LiteralPath -eq '\\wsl.localhost\WinPlaybook\proc\sys\fs\binfmt_misc\WSLInterop' }
        }

        It 'não chama a distribuição' {
            InModuleScope WinPlaybook { Repair-InteropDoWsl -Distribuicao 'WinPlaybook' }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }

    Context 'quando outra distribuição apagou o registro do interop' {
        BeforeEach {
            Mock Test-Path -ModuleName WinPlaybook { $false } -ParameterFilter { $LiteralPath -eq '\\wsl.localhost\WinPlaybook\proc\sys\fs\binfmt_misc\WSLInterop' }
        }

        It 'registra o interop de novo, como root' {
            InModuleScope WinPlaybook { Repair-InteropDoWsl -Distribuicao 'WinPlaybook' }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'WinPlaybook' -and $Usuario -eq 'root' -and $Script.Contains(':WSLInterop:M::MZ::/init:PF') -and $Script.Contains('/proc/sys/fs/binfmt_misc/register')
            }
        }

        It 'registra no log que o interop foi refeito' {
            InModuleScope WinPlaybook { Repair-InteropDoWsl -Distribuicao 'WinPlaybook' }

            Should-Invoke Write-Log -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Nivel -eq 'info' -and $Mensagem -like '*WSLInterop*' }
        }

        It 'não interrompe o comando quando o registro falha' {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 1; Saida = 'Permission denied' } }

            InModuleScope WinPlaybook { Repair-InteropDoWsl -Distribuicao 'WinPlaybook' }

            Should-Invoke Write-Log -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Nivel -eq 'error' -and $Mensagem -like '*Permission denied*' }
        }
    }
}
