BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Copy-Executavel' {
    BeforeEach {
        $pasta = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $pasta
        $origem = Join-Path $TestDrive 'novo.exe'
        Set-Content -LiteralPath $origem -Value 'novo'
        $destino = Join-Path $pasta 'ansible.exe'
    }

    Context 'quando o executável ainda não existe' {
        It 'copia o executável' {
            InModuleScope WinPlaybook -Parameters @{ Origem = $origem; Destino = $destino } { Copy-Executavel -Origem $Origem -Destino $Destino }

            Get-Content -LiteralPath $destino | Should-Be 'novo'
        }
    }

    Context 'quando o executável anterior está aberto' {
        BeforeEach {
            Set-Content -LiteralPath $destino -Value 'antigo'
            $arquivoAberto = [IO.File]::Open($destino, 'Open', 'Read', 'Read, Delete')
        }

        AfterEach {
            $arquivoAberto.Dispose()
        }

        It 'substitui o executável' {
            InModuleScope WinPlaybook -Parameters @{ Origem = $origem; Destino = $destino } { Copy-Executavel -Origem $Origem -Destino $Destino }

            Get-Content -LiteralPath $destino | Should-Be 'novo'
        }

        It 'apaga o anterior numa cópia depois que ele é liberado' {
            InModuleScope WinPlaybook -Parameters @{ Origem = $origem; Destino = $destino } { Copy-Executavel -Origem $Origem -Destino $Destino }
            $arquivoAberto.Dispose()

            InModuleScope WinPlaybook -Parameters @{ Origem = $origem; Destino = $destino } { Copy-Executavel -Origem $Origem -Destino $Destino }

            @(Get-ChildItem -LiteralPath $pasta).Name | Should-BeCollection @('ansible.exe')
        }
    }

    Context 'quando a cópia falha' {
        It 'interrompe o comando' {
            $origemQueNaoExiste = Join-Path $TestDrive 'nao-existe.exe'

            { InModuleScope WinPlaybook -Parameters @{ Origem = $origemQueNaoExiste; Destino = $destino } { Copy-Executavel -Origem $Origem -Destino $Destino } } | Should-Throw
        }
    }
}
