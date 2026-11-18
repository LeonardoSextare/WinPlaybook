BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Register-WinPlaybookArgumentCompleter' {
    BeforeAll {
        $pastaDosShims = Join-Path $TestDrive 'shims'
        $null = New-Item -ItemType Directory -Path $pastaDosShims
        Set-Content -LiteralPath (Join-Path $pastaDosShims 'ansible-teste-completer.ps1') -Value 'shim'
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ ShimFolder = $pastaDosShims } }
        Mock Get-CompletacaoDoAnsible -ModuleName WinPlaybook { '--check' }
        Register-WinPlaybookArgumentCompleter
    }

    It 'completa o comando pelo <_>' -ForEach @('ansible-teste-completer', 'ansible-teste-completer.exe', 'ansible-teste-completer.ps1') {
        $linha = "$_ --ch"

        $resultado = TabExpansion2 -inputScript $linha -cursorColumn $linha.Length

        @($resultado.CompletionMatches | ForEach-Object { $_.CompletionText }) | Should-BeCollection @('--check')
    }

    It 'pede as opções com o nome curto do comando e a linha até o cursor' {
        $linha = 'ansible-teste-completer.exe --ch'

        $null = TabExpansion2 -inputScript $linha -cursorColumn $linha.Length

        Should-Invoke Get-CompletacaoDoAnsible -ModuleName WinPlaybook -ParameterFilter {
            $Comando -eq 'ansible-teste-completer' -and $Linha -eq 'ansible-teste-completer --ch'
        }
    }

    It 'inclui o espaço depois da última palavra na linha' {
        $linha = 'ansible-teste-completer '

        $null = TabExpansion2 -inputScript $linha -cursorColumn $linha.Length

        Should-Invoke Get-CompletacaoDoAnsible -ModuleName WinPlaybook -ParameterFilter {
            $Linha -eq 'ansible-teste-completer '
        }
    }
}
