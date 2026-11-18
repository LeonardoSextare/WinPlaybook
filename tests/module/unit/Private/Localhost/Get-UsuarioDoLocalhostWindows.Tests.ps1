BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $originais = @{ USERNAME = $env:USERNAME; USERDOMAIN = $env:USERDOMAIN; COMPUTERNAME = $env:COMPUTERNAME }
}

AfterAll {
    foreach ($nome in $originais.Keys) {
        Set-Item -LiteralPath "Env:$nome" -Value $originais[$nome]
    }
    Remove-Module WinPlaybook
}

Describe 'Get-UsuarioDoLocalhostWindows' {
    It 'devolve <Esperado> para <Descricao>' -ForEach @(
        @{ Descricao = 'uma conta local'; Usuario = 'Eu'; Dominio = 'MAQUINA'; Esperado = 'eu' }
        @{ Descricao = 'uma conta de domínio'; Usuario = 'Eu'; Dominio = 'EMPRESA'; Esperado = 'empresa\eu' }
    ) {
        $env:USERNAME = $Usuario
        $env:USERDOMAIN = $Dominio
        $env:COMPUTERNAME = 'MAQUINA'

        InModuleScope WinPlaybook { Get-UsuarioDoLocalhostWindows } | Should-Be $Esperado
    }
}
