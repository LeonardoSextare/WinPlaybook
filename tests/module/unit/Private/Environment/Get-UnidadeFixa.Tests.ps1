BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-UnidadeFixa' {
    It 'devolve a unidade do sistema, em minúscula' {
        $unidades = @(InModuleScope WinPlaybook { Get-UnidadeFixa })

        $unidades | Should-ContainCollection $env:SystemDrive.Substring(0, 1).ToLowerInvariant()
    }
}
