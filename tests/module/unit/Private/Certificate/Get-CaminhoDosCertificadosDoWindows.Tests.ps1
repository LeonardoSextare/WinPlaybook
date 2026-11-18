BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDosCertificadosDoWindows' {
    BeforeAll {
        $tempOriginal = $env:TEMP
        $tmpOriginal = $env:TMP
        $env:TEMP = $env:TMP = Join-Path $TestDrive 'temp'
        $null = New-Item -ItemType Directory -Path $env:TEMP
        $repositorio = New-Object -TypeName Security.Cryptography.X509Certificates.X509Store -ArgumentList 'Root', 'LocalMachine'
        $repositorio.Open('ReadOnly')
        $certificadosDeTeste = @($repositorio.Certificates | Select-Object -First 2)
        $repositorio.Close()
        Mock Get-CertificadoRaizDoWindows -ModuleName WinPlaybook { $certificadosDeTeste }
    }

    AfterAll {
        $env:TEMP = $tempOriginal
        $env:TMP = $tmpOriginal
    }

    It 'grava os certificados em PEM na pasta WinPlaybook da pasta temporária' {
        $caminho = InModuleScope WinPlaybook { Get-CaminhoDosCertificadosDoWindows }

        $caminho | Should-BeLikeString (Join-Path $TestDrive 'temp\WinPlaybook\certificados-*.pem')
        $blocos = [regex]::Matches([IO.File]::ReadAllText($caminho), '-----BEGIN CERTIFICATE-----\n([A-Za-z0-9+/=\n]+)\n-----END CERTIFICATE-----\n')
        @($blocos | ForEach-Object { [Convert]::ToBase64String([Convert]::FromBase64String($_.Groups[1].Value)) }) | Should-BeCollection @($certificadosDeTeste | ForEach-Object { [Convert]::ToBase64String($_.RawData) })
    }

    It 'quebra o base64 em linhas de até 64 caracteres' {
        $caminho = InModuleScope WinPlaybook { Get-CaminhoDosCertificadosDoWindows }

        @([IO.File]::ReadAllLines($caminho) | Where-Object { $_.Length -gt 64 }) | Should-BeCollection @()
    }

    It 'devolve o mesmo arquivo na segunda chamada, sem gravá-lo de novo' {
        $primeiro = InModuleScope WinPlaybook { Get-CaminhoDosCertificadosDoWindows }
        $gravadoEm = (Get-Item -LiteralPath $primeiro).LastWriteTimeUtc

        $segundo = InModuleScope WinPlaybook { Get-CaminhoDosCertificadosDoWindows }

        $segundo | Should-Be $primeiro
        (Get-Item -LiteralPath $segundo).LastWriteTimeUtc | Should-Be $gravadoEm
    }

    It 'grava outro arquivo quando os certificados do Windows mudam' {
        $antes = InModuleScope WinPlaybook { Get-CaminhoDosCertificadosDoWindows }
        Mock Get-CertificadoRaizDoWindows -ModuleName WinPlaybook { $certificadosDeTeste[0] }

        $depois = InModuleScope WinPlaybook { Get-CaminhoDosCertificadosDoWindows }

        $depois | Should-NotBe $antes
    }
}
