BeforeDiscovery {
    $raizDoRepositorio = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
    $arquivosComTextoNaoAscii = foreach ($pasta in 'module', 'tests') {
        $arquivos = Get-ChildItem -LiteralPath (Join-Path $raizDoRepositorio $pasta) -Recurse -File |
            Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1' }
        foreach ($arquivo in $arquivos) {
            $temTextoNaoAscii = @([IO.File]::ReadAllBytes($arquivo.FullName) -gt 127).Count -gt 0
            if ($temTextoNaoAscii) {
                Write-Output @{
                    Caminho         = $arquivo.FullName
                    CaminhoRelativo = $arquivo.FullName.Substring($raizDoRepositorio.Length + 1)
                }
            }
        }
    }
}

Describe 'Codificação dos arquivos do PowerShell' {
    It 'grava <CaminhoRelativo> em UTF-8 com BOM, porque ele tem texto não ASCII' -ForEach $arquivosComTextoNaoAscii {
        $bytes = [IO.File]::ReadAllBytes($Caminho)

        $temBom = $bytes.Count -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

        $temBom | Should-BeTrue
    }
}
