BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-PastaVazia' {
    It 'apaga uma pasta vazia' {
        $pastaVazia = (New-Item -ItemType Directory -Path (Join-Path $TestDrive 'vazia')).FullName

        InModuleScope WinPlaybook -Parameters @{ Pasta = $pastaVazia } { Remove-PastaVazia -Pasta $Pasta }

        Test-Path -LiteralPath $pastaVazia | Should-BeFalse
    }

    It 'mantém uma pasta com arquivos' {
        $pastaComArquivos = (New-Item -ItemType Directory -Path (Join-Path $TestDrive 'com-arquivos')).FullName
        Set-Content -LiteralPath (Join-Path $pastaComArquivos 'arquivo.txt') -Value 'mantido'

        InModuleScope WinPlaybook -Parameters @{ Pasta = $pastaComArquivos } { Remove-PastaVazia -Pasta $Pasta }

        Test-Path -LiteralPath $pastaComArquivos | Should-BeTrue
    }

    It 'ignora uma pasta que não existe' {
        $pastaInexistente = Join-Path $TestDrive 'inexistente'

        $resultado = InModuleScope WinPlaybook -Parameters @{ Pasta = $pastaInexistente } { Remove-PastaVazia -Pasta $Pasta }

        $resultado | Should-BeNull
    }
}
