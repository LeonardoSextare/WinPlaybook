BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Update-VersaoMaisNovaGuardada' {
    BeforeEach {
        $pastaDeConfiguracao = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
    }

    It 'guarda a versão mais nova e a hora da consulta' {
        Mock Get-VersaoMaisNovaDoWinPlaybook -ModuleName WinPlaybook { [version] '0.20.0' }

        InModuleScope WinPlaybook { Update-VersaoMaisNovaGuardada }

        $guardada = Get-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'versao-mais-nova.json') -Raw | ConvertFrom-Json
        $guardada.versao | Should-Be '0.20.0'
        ((Get-Date) - [datetime] $guardada.verificadoEm).TotalMinutes | Should-BeLessThan 1
    }

    It 'guarda só a hora quando a Gallery não responde' {
        Mock Get-VersaoMaisNovaDoWinPlaybook -ModuleName WinPlaybook { throw 'sem internet' }

        InModuleScope WinPlaybook { Update-VersaoMaisNovaGuardada }

        $guardada = Get-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'versao-mais-nova.json') -Raw | ConvertFrom-Json
        $guardada.versao | Should-Be ''
    }
}
