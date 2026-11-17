BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'New-ExecutavelDoRelay' {
    BeforeAll {
        $caminhoDosArgumentos = Join-Path $TestDrive 'argumentos-do-compilador.txt'
        $caminhoDoCompilador = Join-Path $TestDrive 'compilador-que-funciona.cmd'
        Set-Content -LiteralPath $caminhoDoCompilador -Value "@echo %* > `"$caminhoDosArgumentos`"", '@exit /b 0'
        Mock Get-CaminhoDoCompiladorCSharp -ModuleName WinPlaybook { $caminhoDoCompilador }
        $caminhoDoExecutavel = Join-Path $TestDrive 'pasta-nova/relay-do-agente-ssh.exe'

        InModuleScope WinPlaybook -Parameters @{ Caminho = $caminhoDoExecutavel } { New-ExecutavelDoRelay -Caminho $Caminho }
        $argumentosDoCompilador = Get-Content -LiteralPath $caminhoDosArgumentos -Raw
    }

    It 'compila o RelayDoAgenteSsh.cs do módulo' {
        $caminhoDoCodigo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/RelayDoAgenteSsh.cs'))

        $argumentosDoCompilador | Should-BeLikeString "*$caminhoDoCodigo*"
    }

    It 'grava o executável no caminho escolhido' {
        $argumentosDoCompilador | Should-BeLikeString "*/out:$caminhoDoExecutavel*"
    }
}
