BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'New-ChaveDoLocalhostWindows' {
    It 'cria a chave no disco da distribuição e devolve a chave pública' {
        Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = "ssh-ed25519 AAAA winplaybook`n" } }

        $chave = InModuleScope WinPlaybook { New-ChaveDoLocalhostWindows -Distribuicao 'WinPlaybook' }

        $chave | Should-Be 'ssh-ed25519 AAAA winplaybook'
        Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Usuario -eq 'winplaybook' -and $Script.Contains('ssh-keygen -q -t ed25519') -and $Script.Contains('$HOME/.config/winplaybook') }
    }

    It 'explica quando não consegue criar a chave' {
        Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 1; Saida = 'sem espaço' } }

        { InModuleScope WinPlaybook { New-ChaveDoLocalhostWindows -Distribuicao 'WinPlaybook' } } | Should-Throw -ExceptionMessage '*chave SSH do localhost_windows*sem espaço'
    }
}
