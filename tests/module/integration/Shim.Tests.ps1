BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Shim.ps1')
    $caminhoDoPowerShell = (Get-Process -Id $PID).Path
}

Describe 'Shim' {
    Context 'quando o alvo mostra os argumentos que recebeu' {
        BeforeAll {
            $caminhoDoScript = Join-Path $TestDrive 'mostra-argumentos.ps1'
            Set-Content -LiteralPath $caminhoDoScript -Value '$args | ForEach-Object { "[$_]" }'
            $caminhoDoShim = New-ShimDeTeste -Pasta $TestDrive -Nome 'mostra-argumentos' -CaminhoDoAlvo $caminhoDoPowerShell `
                -ArgumentosDoAlvo "-NoProfile -ExecutionPolicy Bypass -File `"$caminhoDoScript`""
        }

        It 'passa <Descricao> sem mudança' -ForEach @(
            @{ Descricao = 'JSON com aspas e espaços'; Argumentos = '"{\"x\": \"y z\"}"'; Esperado = '[{"x": "y z"}]' }
            @{ Descricao = 'um sinal de porcentagem'; Argumentos = 'discount=50%PATH%'; Esperado = '[discount=50%PATH%]' }
            @{ Descricao = 'um acento circunflexo'; Argumentos = 'a^b'; Esperado = '[a^b]' }
            @{ Descricao = 'um e comercial'; Argumentos = 'a&b'; Esperado = '[a&b]' }
            @{ Descricao = 'um caminho com espaços'; Argumentos = '"folder with spaces\site.yml"'; Esperado = '[folder with spaces\site.yml]' }
        ) {
            $resultado = Invoke-LinhaDeComando -Programa $caminhoDoShim -Argumentos $Argumentos

            $resultado.Saida | Should-Be $Esperado
        }

        It 'passa vários argumentos na ordem' {
            $resultado = Invoke-LinhaDeComando -Programa $caminhoDoShim -Argumentos '-i inventory.yml site.yml'

            $resultado.Saida -split '\r?\n' | Should-BeCollection @('[-i]', '[inventory.yml]', '[site.yml]')
        }
    }

    Context 'quando o alvo sai com um código' {
        BeforeAll {
            $caminhoDoShim = New-ShimDeTeste -Pasta $TestDrive -Nome 'sai-com' -CaminhoDoAlvo $caminhoDoPowerShell `
                -ArgumentosDoAlvo '-NoProfile -Command exit 7'
        }

        It 'propaga o código de saída do alvo' {
            $resultado = Invoke-LinhaDeComando -Programa $caminhoDoShim

            $resultado.CodigoDeSaida | Should-Be 7
        }
    }
}
