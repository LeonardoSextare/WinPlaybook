BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Uninstall-ServidorOpenSsh' {
    It 'desinstala o recurso OpenSSH Server' {
        Mock Get-WindowsCapability -ModuleName WinPlaybook { [pscustomobject]@{ Name = 'OpenSSH.Server~~~~0.0.1.0' } }
        Mock Remove-WindowsCapability -ModuleName WinPlaybook { }

        InModuleScope WinPlaybook { Uninstall-ServidorOpenSsh }

        Should-Invoke Remove-WindowsCapability -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Name -eq 'OpenSSH.Server~~~~0.0.1.0' }
    }
}
