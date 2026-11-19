BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-OpenSshDoWinPlaybook' {
    BeforeAll {
        $origem = Join-Path $TestDrive 'origem/OpenSSH-Win64'
        $null = New-Item -ItemType Directory -Path $origem -Force
        [IO.File]::WriteAllText((Join-Path $origem 'sshd.exe'), 'sshd falso')
        $zipCerto = Join-Path $TestDrive 'OpenSSH-Win64.zip'
        Compress-Archive -Path $origem -DestinationPath $zipCerto -Force
        $hashCerto = (Get-FileHash -LiteralPath $zipCerto -Algorithm SHA256).Hash
    }

    BeforeEach {
        $pasta = Join-Path $TestDrive "openssh-$([guid]::NewGuid().ToString('N'))"
        Mock Get-PastaDoOpenSshDoWinPlaybook -ModuleName WinPlaybook { $pasta }
        Mock Get-PacoteDoOpenSsh -ModuleName WinPlaybook { @{ Versao = '10.4'; Url = 'https://exemplo/OpenSSH-Win64.zip'; Sha256 = $hashCerto } }
        Mock Invoke-WebRequest -ModuleName WinPlaybook { Copy-Item -LiteralPath $zipCerto -Destination $OutFile }
        Mock icacls.exe -ModuleName WinPlaybook { }
    }

    It 'baixa o zip, confere o hash e deixa o OpenSSH na pasta do WinPlaybook' {
        $resultado = InModuleScope WinPlaybook { Install-OpenSshDoWinPlaybook }

        $resultado | Should-Be $pasta
        Get-Content -LiteralPath (Join-Path $pasta 'sshd.exe') -Raw | Should-Be 'sshd falso'
        Should-Invoke icacls.exe -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -like '*/inheritance:r*S-1-5-18*S-1-5-32-544*S-1-5-32-545:(OI)(CI)RX*' }
    }

    It 'não baixa de novo a mesma versão' {
        $null = InModuleScope WinPlaybook { Install-OpenSshDoWinPlaybook }

        $null = InModuleScope WinPlaybook { Install-OpenSshDoWinPlaybook }

        Should-Invoke Invoke-WebRequest -ModuleName WinPlaybook -Times 1 -Exactly
    }

    It 'recusa um zip que não confere com o hash' {
        Mock Get-PacoteDoOpenSsh -ModuleName WinPlaybook { @{ Versao = '10.4'; Url = 'https://exemplo/OpenSSH-Win64.zip'; Sha256 = 'ERRADO' } }

        { InModuleScope WinPlaybook { Install-OpenSshDoWinPlaybook } } | Should-Throw -ExceptionMessage '*não confere com o arquivo esperado*'
        Test-Path -LiteralPath $pasta | Should-BeFalse
    }

    It 'explica quando o download falha' {
        Mock Invoke-WebRequest -ModuleName WinPlaybook { throw 'sem conexão' }

        { InModuleScope WinPlaybook { Install-OpenSshDoWinPlaybook } } | Should-Throw -ExceptionMessage '*Não foi possível baixar o OpenSSH*GitHub*sem conexão*'
    }
}
