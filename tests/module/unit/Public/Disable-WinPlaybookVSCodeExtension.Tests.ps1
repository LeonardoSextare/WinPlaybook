BeforeAll {
    . (Join-Path $PSScriptRoot '../../helpers/VSCode.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Disable-WinPlaybookVSCodeExtension' {
    BeforeEach {
        $pastaDasExtensoes = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $extensao = New-ExtensaoAnsibleFalsa -PastaDasExtensoes $pastaDasExtensoes -Versao '26.11.0'
        $arquivo = Join-Path $extensao 'packages\ansible-language-server\dist\utils\commandRunner.cjs'
        $original = [IO.File]::ReadAllText($arquivo)
        Mock Get-PastaDasExtensoesDoVSCode -ModuleName WinPlaybook { $pastaDasExtensoes }
        $null = Enable-WinPlaybookVSCodeExtension
    }

    It 'devolve os arquivos originais da extensão' {
        Disable-WinPlaybookVSCodeExtension

        [IO.File]::ReadAllText($arquivo) | Should-Be $original
    }

    It 'não altera nada com -WhatIf' {
        Disable-WinPlaybookVSCodeExtension -WhatIf

        [IO.File]::ReadAllText($arquivo) | Should-NotBe $original
    }
}
