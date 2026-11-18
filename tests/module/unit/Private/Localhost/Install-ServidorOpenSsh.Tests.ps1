BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-ServidorOpenSsh' {
    It 'não instala nada quando o sshd do Windows já existe' {
        Mock Test-Path -ModuleName WinPlaybook { $true }
        Mock Add-WindowsCapability -ModuleName WinPlaybook { }

        $instalou = InModuleScope WinPlaybook { Install-ServidorOpenSsh }

        $instalou | Should-BeFalse
        Should-Invoke Add-WindowsCapability -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'instala o recurso OpenSSH Server quando falta' {
        Mock Test-Path -ModuleName WinPlaybook { $false }
        Mock Get-WindowsCapability -ModuleName WinPlaybook { [pscustomobject]@{ Name = 'OpenSSH.Server~~~~0.0.1.0' } }
        Mock Add-WindowsCapability -ModuleName WinPlaybook { }

        $instalou = InModuleScope WinPlaybook { Install-ServidorOpenSsh }

        $instalou | Should-BeTrue
        Should-Invoke Add-WindowsCapability -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Name -eq 'OpenSSH.Server~~~~0.0.1.0' }
    }
}
