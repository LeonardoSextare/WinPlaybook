BeforeDiscovery {
    $pastaDoModulo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../module/WinPlaybook'))
    $mensagensEmPortugues = Import-PowerShellDataFile -LiteralPath (Join-Path $pastaDoModulo 'pt-BR/Mensagens.psd1')
    $mensagens = foreach ($chave in $mensagensEmPortugues.Keys) {
        Write-Output @{ Chave = $chave }
    }

    $arquivosDoModulo = Get-ChildItem -LiteralPath $pastaDoModulo -Recurse -File | Where-Object { $_.Extension -eq '.ps1' }
    $mensagensUsadas = foreach ($arquivo in $arquivosDoModulo) {
        foreach ($uso in [regex]::Matches([IO.File]::ReadAllText($arquivo.FullName), "Get-Mensagem -Nome '(\w+)'")) {
            Write-Output @{ Chave = $uso.Groups[1].Value; Arquivo = $arquivo.Name }
        }
    }
}

BeforeAll {
    $pastaDoModulo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../module/WinPlaybook'))
    $mensagensEmPortugues = Import-PowerShellDataFile -LiteralPath (Join-Path $pastaDoModulo 'pt-BR/Mensagens.psd1')
    $mensagensEmIngles = Import-PowerShellDataFile -LiteralPath (Join-Path $pastaDoModulo 'en-US/Mensagens.psd1')
}

Describe 'Mensagens do módulo' {
    It 'tem as mesmas chaves em português e em inglês' {
        $chavesEmPortugues = @($mensagensEmPortugues.Keys | Sort-Object)

        Should-BeCollection -Actual @($mensagensEmIngles.Keys | Sort-Object) -Expected $chavesEmPortugues
    }

    It 'tem os mesmos marcadores nos dois idiomas em <Chave>' -ForEach $mensagens {
        $marcadoresEmPortugues = @([regex]::Matches($mensagensEmPortugues[$Chave], '\{\d+\}') | ForEach-Object { $_.Value } | Sort-Object -Unique)

        $marcadoresEmIngles = @([regex]::Matches("$($mensagensEmIngles[$Chave])", '\{\d+\}') | ForEach-Object { $_.Value } | Sort-Object -Unique)

        ($marcadoresEmIngles -join ' ') | Should-Be ($marcadoresEmPortugues -join ' ')
    }

    It 'tem a mensagem <Chave>, que o <Arquivo> usa' -ForEach $mensagensUsadas {
        $mensagensEmPortugues.ContainsKey($Chave) | Should-BeTrue
    }
}
