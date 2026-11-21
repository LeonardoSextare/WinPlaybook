BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ValorDoRegistro' {
    It 'devolve um valor que existe no registro' {
        $valor = InModuleScope WinPlaybook { Get-ValorDoRegistro -Chave 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Nome 'CurrentBuild' }

        $valor | Should-Be (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
    }

    It 'devolve $null quando a chave não existe' {
        $valor = InModuleScope WinPlaybook { Get-ValorDoRegistro -Chave "HKEY_LOCAL_MACHINE\SOFTWARE\WinPlaybookInexistente$([guid]::NewGuid().ToString('N'))" -Nome 'Valor' }

        $valor | Should-BeNull
    }
}