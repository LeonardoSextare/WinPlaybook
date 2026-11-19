BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-EscolhaDaInstalacao' {
    BeforeEach {
        Mock Read-Escolha -ModuleName WinPlaybook { $true }
        Mock Get-PastaDasExtensoesDoVSCode -ModuleName WinPlaybook { Join-Path $TestDrive 'extensoes' }
        Mock Get-ExtensaoAnsibleDoVSCode -ModuleName WinPlaybook { [pscustomobject]@{ Versao = '26.11.0'; Caminho = (Join-Path $TestDrive 'extensoes/redhat.ansible-26.11.0') } }
        Mock Test-SessaoInterativa -ModuleName WinPlaybook { $true }
    }

    It 'pergunta sobre o localhost_windows e o VS Code e devolve as escolhas' {
        $escolhas = InModuleScope WinPlaybook { Get-EscolhaDaInstalacao -Configuracao @{} }

        $escolhas.LigarLocalhost | Should-BeTrue
        $escolhas.CorrigirVSCode | Should-BeTrue
        Should-Invoke Read-Escolha -ModuleName WinPlaybook -Times 2 -Exactly
    }

    It 'guarda a recusa do localhost_windows na configuração' {
        Mock Read-Escolha -ModuleName WinPlaybook { $false }
        $configuracao = @{}

        $null = InModuleScope WinPlaybook -Parameters @{ Configuracao = $configuracao } { Get-EscolhaDaInstalacao -Configuracao $Configuracao }

        $configuracao['LocalhostWindowsDeclined'] | Should-BeTrue
    }

    It 'não pergunta <Descricao>' -ForEach @(
        @{ Descricao = 'fora de um terminal interativo'; Configuracao = @{}; Interativa = $false; Extensoes = 1 }
        @{ Descricao = 'com o localhost_windows já ligado e sem a extensão'; Configuracao = @{ LocalhostWindowsPort = 47022 }; Interativa = $true; Extensoes = 0 }
        @{ Descricao = 'depois de uma recusa e sem a extensão'; Configuracao = @{ LocalhostWindowsDeclined = $true }; Interativa = $true; Extensoes = 0 }
    ) {
        Mock Test-SessaoInterativa -ModuleName WinPlaybook -MockWith ([scriptblock]::Create("`$$Interativa"))
        if ($Extensoes -eq 0) { Mock Get-ExtensaoAnsibleDoVSCode -ModuleName WinPlaybook { } }

        $null = InModuleScope WinPlaybook -Parameters @{ Configuracao = $Configuracao } { Get-EscolhaDaInstalacao -Configuracao $Configuracao }

        Should-Invoke Read-Escolha -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'liga sem perguntar com os switches' {
        $escolhas = InModuleScope WinPlaybook { Get-EscolhaDaInstalacao -Configuracao @{} -LigarLocalhost -CorrigirVSCode }

        $escolhas.LigarLocalhost | Should-BeTrue
        $escolhas.CorrigirVSCode | Should-BeTrue
        Should-Invoke Read-Escolha -ModuleName WinPlaybook -Times 0 -Exactly
    }
}
