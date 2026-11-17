BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDoSupervisor' {
    BeforeAll {
        $tempOriginal = $env:TEMP
        $tmpOriginal = $env:TMP
        $env:TEMP = $env:TMP = Join-Path $TestDrive 'temp'
        $null = New-Item -ItemType Directory -Path $env:TEMP
    }

    AfterAll {
        $env:TEMP = $tempOriginal
        $env:TMP = $tmpOriginal
    }

    It 'grava o script do supervisor na pasta WinPlaybook da pasta temporária' {
        $caminho = InModuleScope WinPlaybook { Get-CaminhoDoSupervisor }

        $caminho | Should-BeLikeString (Join-Path $TestDrive 'temp\WinPlaybook\supervisor-*.py')
        [IO.File]::ReadAllText($caminho) | Should-Be (InModuleScope WinPlaybook { Get-ScriptDoSupervisor })
    }

    It 'devolve o mesmo arquivo na segunda chamada, sem gravá-lo de novo' {
        $primeiro = InModuleScope WinPlaybook { Get-CaminhoDoSupervisor }
        $gravadoEm = (Get-Item -LiteralPath $primeiro).LastWriteTimeUtc

        $segundo = InModuleScope WinPlaybook { Get-CaminhoDoSupervisor }

        $segundo | Should-Be $primeiro
        (Get-Item -LiteralPath $segundo).LastWriteTimeUtc | Should-Be $gravadoEm
    }
}
