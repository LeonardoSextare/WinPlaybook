BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CertificadoRaizDoWindows' {
    BeforeAll {
        $repositorio = New-Object -TypeName Security.Cryptography.X509Certificates.X509Store -ArgumentList 'Root', 'LocalMachine'
        $repositorio.Open('ReadOnly')
        $impressoesDoComputador = @($repositorio.Certificates | ForEach-Object { $_.Thumbprint })
        $repositorio.Close()
    }

    It 'devolve os certificados raiz confiáveis do computador' {
        $impressoes = @(InModuleScope WinPlaybook { Get-CertificadoRaizDoWindows } | ForEach-Object { $_.Thumbprint })

        @($impressoesDoComputador | Where-Object { $impressoes -notcontains $_ }) | Should-BeCollection @()
    }

    It 'devolve cada certificado uma vez só' {
        $impressoes = @(InModuleScope WinPlaybook { Get-CertificadoRaizDoWindows } | ForEach-Object { $_.Thumbprint })

        $impressoes.Count | Should-Be @($impressoes | Select-Object -Unique).Count
    }
}
