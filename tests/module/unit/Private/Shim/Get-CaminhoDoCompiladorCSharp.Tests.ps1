BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDoCompiladorCSharp' {
    It 'devolve o csc.exe do .NET Framework 4 da pasta do Windows' {
        $esperado = Join-Path ([Environment]::GetFolderPath('Windows')) 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

        $resultado = InModuleScope WinPlaybook { Get-CaminhoDoCompiladorCSharp }

        $resultado | Should-Be $esperado
    }
}
