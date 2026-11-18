BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-SshdDoWinPlaybook' {
    It 'apaga o serviço e a pasta da configuração' {
        $pasta = Join-Path $TestDrive 'remover\WinPlaybook\ssh'
        $null = New-Item -ItemType Directory -Path $pasta -Force
        Mock Get-PastaDoSshdDoWinPlaybook -ModuleName WinPlaybook { $pasta }
        Mock Get-Service -ModuleName WinPlaybook { [pscustomobject]@{ Name = 'WinPlaybookSshd' } }
        Mock Stop-Service -ModuleName WinPlaybook { }
        Mock Get-CimInstance -ModuleName WinPlaybook { [pscustomobject]@{ Name = 'WinPlaybookSshd' } }
        Mock Invoke-CimMethod -ModuleName WinPlaybook -RemoveParameterType InputObject { }

        InModuleScope WinPlaybook { Remove-SshdDoWinPlaybook }

        Should-Invoke Invoke-CimMethod -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $MethodName -eq 'Delete' }
        Test-Path -LiteralPath (Split-Path -Parent $pasta) | Should-BeFalse
    }
}
