BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Update-WinPlaybook' {
    BeforeEach {
        Mock Update-ModuloDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Invoke-InstalacaoDaVersaoNova -ModuleName WinPlaybook { }
    }

    It 'atualiza o módulo e depois roda a instalação da versão nova' {
        Update-WinPlaybook

        Should-Invoke Update-ModuloDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly
        Should-Invoke Invoke-InstalacaoDaVersaoNova -ModuleName WinPlaybook -Times 1 -Exactly
    }

    It 'explica o que fazer quando o módulo não foi instalado pela Gallery' {
        Mock Update-ModuloDoWinPlaybook -ModuleName WinPlaybook { throw 'Module WinPlaybook was not installed by using Install-Module' }

        { Update-WinPlaybook } | Should-Throw -ExceptionMessage '*código-fonte, atualize o código e rode o Install-WinPlaybook*was not installed by using Install-Module'
        Should-Invoke Invoke-InstalacaoDaVersaoNova -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'não altera nada com -WhatIf' {
        Update-WinPlaybook -WhatIf

        Should-Invoke Update-ModuloDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
    }
}
