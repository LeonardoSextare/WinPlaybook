BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $nivelOriginal = $env:WINPLAYBOOK_LOG
}

AfterAll {
    Remove-Item -LiteralPath 'Env:WINPLAYBOOK_LOG' -ErrorAction SilentlyContinue
    if ($null -ne $nivelOriginal) {
        $env:WINPLAYBOOK_LOG = $nivelOriginal
    }
    Remove-Module WinPlaybook
}

Describe 'Write-Log' {
    BeforeEach {
        Remove-Item -LiteralPath 'Env:WINPLAYBOOK_LOG' -ErrorAction SilentlyContinue
        $pastaDeConfiguracao = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        $caminhoDoLog = InModuleScope WinPlaybook { Get-CaminhoDoLog }
    }

    It 'grava a data, o nível, o processo e a mensagem' {
        InModuleScope WinPlaybook { Write-Log -Nivel 'info' -Mensagem 'ansible saiu com 0' }

        $linha = @(Get-Content -LiteralPath $caminhoDoLog)[0]
        $linha -match "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2} \[INFO\] \[$PID\] ansible saiu com 0$" | Should-BeTrue -Because $linha
    }

    It 'grava uma linha por registro' {
        InModuleScope WinPlaybook {
            Write-Log -Nivel 'info' -Mensagem 'primeiro'
            Write-Log -Nivel 'error' -Mensagem 'segundo'
        }

        @(Get-Content -LiteralPath $caminhoDoLog).Count | Should-Be 2
    }

    It 'não grava o nível debug no nível padrão' {
        InModuleScope WinPlaybook { Write-Log -Nivel 'debug' -Mensagem 'detalhe' }

        Test-Path -LiteralPath $caminhoDoLog | Should-BeFalse
    }

    It 'grava o nível debug com WINPLAYBOOK_LOG=debug' {
        $env:WINPLAYBOOK_LOG = 'debug'

        InModuleScope WinPlaybook { Write-Log -Nivel 'debug' -Mensagem 'detalhe' }

        Get-Content -LiteralPath $caminhoDoLog -Raw -Encoding UTF8 | Should-BeLikeString '*`[DEBUG`]*detalhe*'
    }

    It 'apaga os logs com mais de 7 dias no primeiro registro do dia' {
        $pastaDosLogs = Split-Path -Parent $caminhoDoLog
        $null = New-Item -ItemType Directory -Path $pastaDosLogs -Force
        $antigo = Join-Path $pastaDosLogs 'winplaybook-2000-01-01.log'
        $recente = Join-Path $pastaDosLogs "winplaybook-$((Get-Date).AddDays(-1).ToString('yyyy-MM-dd')).log"
        Set-Content -LiteralPath $antigo, $recente -Value 'linha'
        (Get-Item -LiteralPath $antigo).LastWriteTime = (Get-Date).AddDays(-8)

        InModuleScope WinPlaybook { Write-Log -Nivel 'info' -Mensagem 'novo dia' }

        Test-Path -LiteralPath $antigo | Should-BeFalse
        Test-Path -LiteralPath $recente | Should-BeTrue
    }

    It 'não interrompe o comando quando não consegue gravar' {
        $null = New-Item -ItemType File -Path $pastaDeConfiguracao -Force

        InModuleScope WinPlaybook { Write-Log -Nivel 'error' -Mensagem 'sem pasta' }

        Test-Path -LiteralPath $pastaDeConfiguracao -PathType Leaf | Should-BeTrue
    }
}
