BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Write-LinhaColoridaNoErro' {
    BeforeEach {
        $noColorDoProcesso = $env:NO_COLOR
        Remove-Item -LiteralPath 'Env:NO_COLOR' -ErrorAction SilentlyContinue
        $corOriginal = [Console]::ForegroundColor
        $erros = [IO.StringWriter]::new()
        $errosOriginais = [Console]::Error
        [Console]::SetError($erros)
    }

    AfterEach {
        [Console]::SetError($errosOriginais)
        $env:NO_COLOR = $noColorDoProcesso
    }

    It 'escreve a linha no stderr' {
        InModuleScope WinPlaybook { Write-LinhaColoridaNoErro -Texto 'versão nova' -Cor 'Yellow' }

        $erros.ToString() | Should-Be "versão nova$([Environment]::NewLine)"
    }

    It 'volta à cor anterior do console' {
        InModuleScope WinPlaybook { Write-LinhaColoridaNoErro -Texto 'versão nova' -Cor 'Yellow' }

        [Console]::ForegroundColor | Should-Be $corOriginal
    }

    It 'escreve a linha também com NO_COLOR' {
        $env:NO_COLOR = '1'

        InModuleScope WinPlaybook { Write-LinhaColoridaNoErro -Texto 'versão nova' -Cor 'Yellow' }

        $erros.ToString() | Should-Be "versão nova$([Environment]::NewLine)"
    }
}
