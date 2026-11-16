BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Shim.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $caminhoDoExecutavel = New-ExecutavelDeShimDeTeste -Pasta (Join-Path $TestDrive 'executavel')
    $pastaDosShims = Join-Path $TestDrive 'shims'
    $null = New-Item -ItemType Directory -Path $pastaDosShims
    $parametrosDosShims = @{
        Pasta               = $pastaDosShims
        CaminhoDoPowerShell = (Get-Process -Id $PID).Path
        PastaDoModulo       = New-ModuloFalso -Pasta (Join-Path $TestDrive 'modulo-falso')
        CaminhoDoExecutavel = $caminhoDoExecutavel
    }
    InModuleScope WinPlaybook -Parameters $parametrosDosShims {
        foreach ($nome in 'mostra-argumentos', 'sai-com', 'le-a-entrada') {
            New-ShimDeComando -Nome $nome -Pasta $Pasta -CaminhoDoPowerShell $CaminhoDoPowerShell -PastaDoModulo $PastaDoModulo -CaminhoDoExecutavel $CaminhoDoExecutavel
        }
    }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Shim' {
    Context 'quando o comando mostra os argumentos que recebeu' {
        It 'passa <Descricao> sem mudança' -ForEach @(
            @{ Descricao = 'JSON com aspas e espaços'; Argumentos = '"{\"x\": \"y z\"}"'; Esperado = '[{"x": "y z"}]' }
            @{ Descricao = 'um sinal de porcentagem'; Argumentos = 'discount=50%PATH%'; Esperado = '[discount=50%PATH%]' }
            @{ Descricao = 'um acento circunflexo'; Argumentos = 'a^b'; Esperado = '[a^b]' }
            @{ Descricao = 'um e comercial'; Argumentos = 'a&b'; Esperado = '[a&b]' }
            @{ Descricao = 'um caminho com espaços'; Argumentos = '"folder with spaces\site.yml"'; Esperado = '[folder with spaces\site.yml]' }
            @{ Descricao = 'um argumento que é só um traço'; Argumentos = '-'; Esperado = '[-]' }
            @{ Descricao = 'uma opção com = e um caminho do Windows'; Argumentos = '--inventory=C:\hosts.yml'; Esperado = '[--inventory=C:\hosts.yml]' }
            @{ Descricao = 'uma opção com dois-pontos'; Argumentos = '-i:hosts.yml'; Esperado = '[-i:hosts.yml]' }
            @{ Descricao = 'um argumento vazio'; Argumentos = '""'; Esperado = '[]' }
            @{ Descricao = 'acentos'; Argumentos = "a$([char]0x00E7)$([char]0x00E3)o"; Esperado = "[a$([char]0x00E7)$([char]0x00E3)o]" }
        ) {
            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims 'mostra-argumentos.exe') -Argumentos $Argumentos

            $resultado.Saida | Should-Be $Esperado -Because $resultado.Erro
        }

        It 'passa vários argumentos na ordem' {
            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims 'mostra-argumentos.exe') -Argumentos '-i inventory.yml site.yml'

            $resultado.Saida -split '\r?\n' | Should-BeCollection @('[-i]', '[inventory.yml]', '[site.yml]')
        }
    }

    Context 'quando o comando sai com um código' {
        It 'propaga o código de saída do comando' {
            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims 'sai-com.exe') -Argumentos '7'

            $resultado.CodigoDeSaida | Should-Be 7 -Because $resultado.Erro
        }
    }

    Context 'quando a entrada padrão é redirecionada' {
        It 'entrega a entrada ao comando' {
            $caminhoDaEntrada = Join-Path $TestDrive 'entrada.txt'
            Set-Content -LiteralPath $caminhoDaEntrada -Value 'oi da entrada'

            $resultado = Invoke-LinhaDeComando -Programa (Join-Path $pastaDosShims 'le-a-entrada.exe') -CaminhoDaEntrada $caminhoDaEntrada

            $resultado.Saida | Should-Be 'entrada=[oi da entrada]' -Because $resultado.Erro
        }
    }

    Context 'quando o .shim do executável não existe' {
        BeforeAll {
            $pastaSemShim = Join-Path $TestDrive 'sem-shim'
            $null = New-Item -ItemType Directory -Path $pastaSemShim
            $caminhoDoExe = Join-Path $pastaSemShim 'ansible.exe'
            Copy-Item -LiteralPath $caminhoDoExecutavel -Destination $caminhoDoExe
        }

        It 'sai com erro e mostra o .shim que falta' {
            $resultado = Invoke-LinhaDeComando -Programa $caminhoDoExe

            $resultado.CodigoDeSaida | Should-Be 1
            $resultado.Erro | Should-BeLikeString "WinPlaybook:*$(Join-Path $pastaSemShim 'ansible.shim')*"
        }
    }
}
