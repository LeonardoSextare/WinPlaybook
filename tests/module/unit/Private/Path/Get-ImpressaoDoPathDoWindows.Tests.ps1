BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ImpressaoDoPathDoWindows' {
    BeforeEach {
        $pastaA = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $pastaB = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $pastaA, $pastaB
        $path = "$pastaA;$pastaB"
    }

    It 'devolve a mesma impressão quando as pastas não mudam' {
        $primeira = InModuleScope WinPlaybook -Parameters @{ Path = $path } { Get-ImpressaoDoPathDoWindows -Path $Path }
        $segunda = InModuleScope WinPlaybook -Parameters @{ Path = $path } { Get-ImpressaoDoPathDoWindows -Path $Path }

        $segunda | Should-Be $primeira
    }

    It 'muda a impressão quando um programa entra numa pasta do Path' {
        $antes = InModuleScope WinPlaybook -Parameters @{ Path = $path } { Get-ImpressaoDoPathDoWindows -Path $Path }
        [IO.Directory]::SetLastWriteTimeUtc($pastaB, [datetime]::UtcNow.AddMinutes(1))

        $depois = InModuleScope WinPlaybook -Parameters @{ Path = $path } { Get-ImpressaoDoPathDoWindows -Path $Path }

        $depois | Should-NotBe $antes
    }

    It 'muda a impressão quando o Path ganha uma pasta' {
        $antes = InModuleScope WinPlaybook -Parameters @{ Path = $path } { Get-ImpressaoDoPathDoWindows -Path $Path }

        $depois = InModuleScope WinPlaybook -Parameters @{ Path = "$path;$TestDrive" } { Get-ImpressaoDoPathDoWindows -Path $Path }

        $depois | Should-NotBe $antes
    }

    It 'aceita uma pasta do Path que não existe' {
        $impressao = InModuleScope WinPlaybook -Parameters @{ Path = "$path;C:\nao\existe" } { Get-ImpressaoDoPathDoWindows -Path $Path }

        $impressao | Should-MatchString '^[0-9a-f]{64}$'
    }
}
