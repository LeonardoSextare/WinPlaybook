BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'New-ExecutavelDeShim' {
    Context 'quando o compilador compila' {
        BeforeAll {
            $caminhoDosArgumentos = Join-Path $TestDrive 'argumentos-do-compilador.txt'
            $caminhoDoCompilador = Join-Path $TestDrive 'compilador-que-funciona.cmd'
            Set-Content -LiteralPath $caminhoDoCompilador -Value "@echo %* > `"$caminhoDosArgumentos`"", '@exit /b 0'
            Mock Get-CaminhoDoCompiladorCSharp -ModuleName WinPlaybook { $caminhoDoCompilador }
            $caminhoDoExecutavel = Join-Path $TestDrive 'pasta-nova/shim.exe'

            InModuleScope WinPlaybook -Parameters @{ Caminho = $caminhoDoExecutavel } { New-ExecutavelDeShim -Caminho $Caminho }
            $argumentosDoCompilador = Get-Content -LiteralPath $caminhoDosArgumentos -Raw
        }

        It 'compila um programa de console a partir do Shim.cs do módulo' {
            $caminhoDoCodigo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/Shim.cs'))

            $argumentosDoCompilador | Should-BeLikeString "*/target:exe*$caminhoDoCodigo*"
        }

        It 'grava o executável no caminho escolhido' {
            $argumentosDoCompilador | Should-BeLikeString "*/out:$caminhoDoExecutavel*"
        }

        It 'cria a pasta do executável' {
            Test-Path -LiteralPath (Split-Path -Path $caminhoDoExecutavel -Parent) | Should-BeTrue
        }
    }

    Context 'quando o compilador falha' {
        BeforeAll {
            $caminhoDoCompilador = Join-Path $TestDrive 'compilador-que-falha.cmd'
            Set-Content -LiteralPath $caminhoDoCompilador -Value '@echo Shim.cs(1,1): error CS1002: ; expected', '@exit /b 1'
            Mock Get-CaminhoDoCompiladorCSharp -ModuleName WinPlaybook { $caminhoDoCompilador }
        }

        It 'mostra a resposta do compilador' {
            { InModuleScope WinPlaybook -Parameters @{ Caminho = (Join-Path $TestDrive 'falha/shim.exe') } { New-ExecutavelDeShim -Caminho $Caminho } } | Should-Throw -ExceptionMessage '*compilar o executável dos shims*error CS1002*'
        }
    }

    Context 'quando o compilador não existe' {
        BeforeAll {
            $caminhoDoCompilador = Join-Path $TestDrive 'sem-dotnet/csc.exe'
            Mock Get-CaminhoDoCompiladorCSharp -ModuleName WinPlaybook { $caminhoDoCompilador }
        }

        It 'explica que falta o .NET Framework e mostra onde procurou' {
            { InModuleScope WinPlaybook -Parameters @{ Caminho = (Join-Path $TestDrive 'sem/shim.exe') } { New-ExecutavelDeShim -Caminho $Caminho } } | Should-Throw -ExceptionMessage "*$caminhoDoCompilador*.NET Framework 4.8*"
        }
    }
}
