BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Save-Configuracao' {
    BeforeAll {
        $pastaDeConfiguracao = Join-Path $TestDrive 'configuracao'
        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }

        InModuleScope WinPlaybook {
            Save-Configuracao -Configuracao @{ ShimFolder = 'C:\Tools\WinPlaybook\bin'; ShimPowerShellPath = 'C:\PowerShell\pwsh.exe' }
        }
    }

    It 'grava a configuração em JSON na pasta de configuração' {
        $configuracaoSalva = Get-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Raw | ConvertFrom-Json

        $configuracaoSalva.ShimFolder | Should-Be 'C:\Tools\WinPlaybook\bin'
    }

    It 'grava uma configuração que o Get-Configuracao lê de volta' {
        $resultado = InModuleScope WinPlaybook { Get-Configuracao }

        $resultado.ShimPowerShellPath | Should-Be 'C:\PowerShell\pwsh.exe'
    }
}
