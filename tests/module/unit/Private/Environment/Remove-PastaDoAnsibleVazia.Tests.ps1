BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-PastaDoAnsibleVazia' {
    BeforeEach {
        $pastaDoPerfil = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $pastaDoPerfil '.ansible\collections'), (Join-Path $pastaDoPerfil '.ansible\roles') -Force
    }

    It 'apaga a pasta .ansible quando as pastas dela estão vazias' {
        InModuleScope WinPlaybook -Parameters @{ PastaDoPerfil = $pastaDoPerfil } { Remove-PastaDoAnsibleVazia -PastaDoPerfil $PastaDoPerfil }

        Test-Path -LiteralPath (Join-Path $pastaDoPerfil '.ansible') | Should-BeFalse
    }

    It 'mantém uma pasta com arquivos e as pastas acima dela' {
        $null = New-Item -ItemType File -Path (Join-Path $pastaDoPerfil '.ansible\roles\minha_role\tasks\main.yml') -Force

        InModuleScope WinPlaybook -Parameters @{ PastaDoPerfil = $pastaDoPerfil } { Remove-PastaDoAnsibleVazia -PastaDoPerfil $PastaDoPerfil }

        Test-Path -LiteralPath (Join-Path $pastaDoPerfil '.ansible\roles\minha_role\tasks\main.yml') | Should-BeTrue
        Test-Path -LiteralPath (Join-Path $pastaDoPerfil '.ansible\collections') | Should-BeFalse
    }

    It 'mantém outros arquivos da pasta .ansible' {
        $null = New-Item -ItemType File -Path (Join-Path $pastaDoPerfil '.ansible\galaxy_token') -Force

        InModuleScope WinPlaybook -Parameters @{ PastaDoPerfil = $pastaDoPerfil } { Remove-PastaDoAnsibleVazia -PastaDoPerfil $PastaDoPerfil }

        Test-Path -LiteralPath (Join-Path $pastaDoPerfil '.ansible\galaxy_token') | Should-BeTrue
    }
}
