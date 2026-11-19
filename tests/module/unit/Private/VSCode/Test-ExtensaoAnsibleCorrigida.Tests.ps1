BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Test-ExtensaoAnsibleCorrigida' {
    It 'devolve <Esperado> <Descricao>' -ForEach @(
        @{ Descricao = 'com um arquivo original guardado'; Corrigida = $true; Esperado = $true }
        @{ Descricao = 'sem arquivo original'; Corrigida = $false; Esperado = $false }
    ) {
        $pasta = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $pasta 'out') -Force
        if ($Corrigida) { $null = New-Item -ItemType File -Path (Join-Path $pasta 'out/server.js.winplaybook-original') }

        InModuleScope WinPlaybook -Parameters @{ Pasta = $pasta } { Test-ExtensaoAnsibleCorrigida -Caminho $Pasta } | Should-Be $Esperado
    }
}
