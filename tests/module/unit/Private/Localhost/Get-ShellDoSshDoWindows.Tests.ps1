BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ShellDoSshDoWindows' {
    It 'devolve <Esperado> com o DefaultShell <Descricao>' -ForEach @(
        @{ Descricao = 'no Windows PowerShell'; Valor = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'; Esperado = 'powershell' }
        @{ Descricao = 'no PowerShell 7, entre aspas'; Valor = '"C:\Program Files\PowerShell\7\pwsh.exe"'; Esperado = 'powershell' }
        @{ Descricao = 'no cmd'; Valor = 'C:\Windows\System32\cmd.exe'; Esperado = 'cmd' }
        @{ Descricao = 'sem valor, o padrão do OpenSSH'; Valor = $null; Esperado = 'cmd' }
    ) {
        Mock Get-ValorDoRegistro -ModuleName WinPlaybook -ParameterFilter { $Chave -eq 'HKEY_LOCAL_MACHINE\SOFTWARE\OpenSSH' -and $Nome -eq 'DefaultShell' } { $Valor }

        $shell = InModuleScope WinPlaybook { Get-ShellDoSshDoWindows }

        $shell | Should-Be $Esperado
    }
}