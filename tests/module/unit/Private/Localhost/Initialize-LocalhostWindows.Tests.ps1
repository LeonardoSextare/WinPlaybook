BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Initialize-LocalhostWindows' {
    BeforeEach {
        Mock Enable-WinPlaybookLocalhost -ModuleName WinPlaybook { }
        Mock Read-EscolhaDoLocalhostWindows -ModuleName WinPlaybook { $true }
        Mock Test-SessaoInterativa -ModuleName WinPlaybook { $true }
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'WinPlaybook' } }
        Mock Save-Configuracao -ModuleName WinPlaybook { }
    }

    It 'liga sem perguntar com -Ligar' {
        InModuleScope WinPlaybook { Initialize-LocalhostWindows -Configuracao @{} -Ligar }

        Should-Invoke Enable-WinPlaybookLocalhost -ModuleName WinPlaybook -Times 1 -Exactly
        Should-Invoke Read-EscolhaDoLocalhostWindows -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'liga quando o usuário aceita' {
        InModuleScope WinPlaybook { Initialize-LocalhostWindows -Configuracao @{} }

        Should-Invoke Enable-WinPlaybookLocalhost -ModuleName WinPlaybook -Times 1 -Exactly
    }

    It 'guarda a recusa do usuário e não liga' {
        Mock Read-EscolhaDoLocalhostWindows -ModuleName WinPlaybook { $false }

        InModuleScope WinPlaybook { Initialize-LocalhostWindows -Configuracao @{} }

        Should-Invoke Enable-WinPlaybookLocalhost -ModuleName WinPlaybook -Times 0 -Exactly
        Should-Invoke Save-Configuracao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Configuracao['LocalhostWindowsDeclined'] -eq $true }
    }

    It 'não pergunta <Descricao>' -ForEach @(
        @{ Descricao = 'com o localhost_windows já ligado'; Configuracao = @{ LocalhostWindowsPort = 47022 }; Interativa = $true }
        @{ Descricao = 'depois de uma recusa'; Configuracao = @{ LocalhostWindowsDeclined = $true }; Interativa = $true }
        @{ Descricao = 'fora de um terminal interativo'; Configuracao = @{}; Interativa = $false }
    ) {
        Mock Test-SessaoInterativa -ModuleName WinPlaybook -MockWith ([scriptblock]::Create("`$$Interativa"))

        InModuleScope WinPlaybook -Parameters @{ Configuracao = $Configuracao } { Initialize-LocalhostWindows -Configuracao $Configuracao }

        Should-Invoke Read-EscolhaDoLocalhostWindows -ModuleName WinPlaybook -Times 0 -Exactly
        Should-Invoke Enable-WinPlaybookLocalhost -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'avisa como ligar depois, sem falhar, quando a ligação falha' {
        Mock Enable-WinPlaybookLocalhost -ModuleName WinPlaybook { throw 'elevação recusada.' }

        $avisos = InModuleScope WinPlaybook { Initialize-LocalhostWindows -Configuracao @{} 3>&1 }

        "$avisos" | Should-BeLikeString '*elevação recusada.*Enable-WinPlaybookLocalhost*'
    }
}
