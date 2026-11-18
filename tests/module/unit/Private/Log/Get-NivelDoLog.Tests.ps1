BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $nivelOriginal = $env:WINPLAYBOOK_LOG
}

AfterAll {
    Remove-Item -LiteralPath 'Env:WINPLAYBOOK_LOG' -ErrorAction SilentlyContinue
    if ($null -ne $nivelOriginal) {
        $env:WINPLAYBOOK_LOG = $nivelOriginal
    }
    Remove-Module WinPlaybook
}

Describe 'Get-NivelDoLog' {
    It 'devolve <Esperado> com WINPLAYBOOK_LOG=<Valor>' -ForEach @(
        @{ Valor = 'off'; Esperado = 0 }
        @{ Valor = 'error'; Esperado = 1 }
        @{ Valor = 'info'; Esperado = 2 }
        @{ Valor = 'debug'; Esperado = 3 }
        @{ Valor = ' DEBUG '; Esperado = 3 }
        @{ Valor = 'verboso'; Esperado = 2 }
    ) {
        $env:WINPLAYBOOK_LOG = $Valor

        InModuleScope WinPlaybook { Get-NivelDoLog } | Should-Be $Esperado
    }

    It 'usa o nível info sem a variável' {
        Remove-Item -LiteralPath 'Env:WINPLAYBOOK_LOG' -ErrorAction SilentlyContinue

        InModuleScope WinPlaybook { Get-NivelDoLog } | Should-Be 2
    }
}
