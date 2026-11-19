BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PassoDoLocalhostWindows' {
    It 'devolve, para ligar, o título, a aprovação e as etapas, quando o PowerShell não é de administrador' {
        Mock Test-Administrador -ModuleName WinPlaybook { $false }

        $ids = InModuleScope WinPlaybook { Get-PassoDoLocalhostWindows | ForEach-Object { $_.Id } }

        Should-BeCollection -Actual $ids -Expected @('localhost', 'localhost.aprovacao', 'localhost.chave', 'localhost.openssh', 'localhost.servico')
    }

    It 'não espera aprovação num PowerShell de administrador' {
        Mock Test-Administrador -ModuleName WinPlaybook { $true }

        $ids = InModuleScope WinPlaybook { Get-PassoDoLocalhostWindows -Desligar | ForEach-Object { $_.Id } }

        Should-BeCollection -Actual $ids -Expected @('localhost', 'localhost.remover')
    }
}
