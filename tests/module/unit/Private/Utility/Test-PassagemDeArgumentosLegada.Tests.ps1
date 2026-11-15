BeforeDiscovery {
    $temPassagemModerna = $PSVersionTable.PSVersion -ge [version] '7.3'
}

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $formaDePassagemOriginal = Get-Variable -Name 'PSNativeCommandArgumentPassing' -Scope Global -ValueOnly -ErrorAction SilentlyContinue
}

AfterAll {
    Set-Variable -Name 'PSNativeCommandArgumentPassing' -Scope Global -Value $formaDePassagemOriginal -ErrorAction SilentlyContinue
    Remove-Module WinPlaybook
}

Describe 'Test-PassagemDeArgumentosLegada' {
    Context 'quando o PowerShell é anterior ao 7.3' -Skip:$temPassagemModerna {
        It 'devolve verdadeiro' {
            $resultado = InModuleScope WinPlaybook { Test-PassagemDeArgumentosLegada }

            $resultado | Should-BeTrue
        }
    }

    Context 'quando o PowerShell 7.3 em diante passa os argumentos na forma <Forma>' -Skip:(-not $temPassagemModerna) -ForEach @(
        @{ Forma = 'Windows'; Esperado = $false }
        @{ Forma = 'Standard'; Esperado = $false }
        @{ Forma = 'Legacy'; Esperado = $true }
    ) {
        BeforeAll {
            $global:PSNativeCommandArgumentPassing = $Forma
        }

        It 'devolve <Esperado>' {
            $resultado = InModuleScope WinPlaybook { Test-PassagemDeArgumentosLegada }

            $resultado | Should-Be $Esperado
        }
    }
}
