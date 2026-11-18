BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Invoke-ComoAdministrador' {
    It 'roda o comando num PowerShell elevado, com o módulo' {
        Mock Start-Process -ModuleName WinPlaybook { [pscustomobject]@{ ExitCode = 0 } }

        InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost -Confirm:$false' }

        Should-Invoke Start-Process -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $script = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ArgumentList[2]))
            $Verb -eq 'RunAs' -and $Wait -and $script -like "*Import-Module '*'; Enable-WinPlaybookLocalhost -Confirm:`$false"
        }
    }

    It 'explica quando o comando elevado falha' {
        Mock Start-Process -ModuleName WinPlaybook { [pscustomobject]@{ ExitCode = 1 } }

        { InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost' } } | Should-Throw -ExceptionMessage '*Enable-WinPlaybookLocalhost falhou no PowerShell de administrador*'
    }

    It 'explica quando o Windows não abre o PowerShell elevado' {
        Mock Start-Process -ModuleName WinPlaybook { throw 'A operação foi cancelada pelo usuário.' }

        { InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost' } } | Should-Throw -ExceptionMessage '*não abriu o PowerShell de administrador*cancelada pelo usuário*'
    }
}
