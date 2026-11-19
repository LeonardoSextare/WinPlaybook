BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Invoke-ComoAdministrador' {
    BeforeAll {
        function New-ProcessoFalso([int] $CodigoDeSaida) {
            $processo = [pscustomobject]@{ ExitCode = $CodigoDeSaida; HasExited = $true }
            $processo | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { param($Milissegundos) $true }
            return $processo
        }
    }

    It 'roda o comando num PowerShell elevado, com o módulo' {
        Mock Start-Process -ModuleName WinPlaybook { New-ProcessoFalso 0 }

        InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost -Confirm:$false' }

        Should-Invoke Start-Process -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $script = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ArgumentList[4]))
            $Verb -eq 'RunAs' -and $WindowStyle -eq 'Hidden' -and $script -like "*Import-Module '*'; Enable-WinPlaybookLocalhost -Confirm:`$false }*"
        }
    }

    It 'explica quando o comando elevado falha' {
        Mock Start-Process -ModuleName WinPlaybook { New-ProcessoFalso 1 }

        { InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost' } } | Should-Throw -ExceptionMessage '*Enable-WinPlaybookLocalhost falhou como administrador*'
    }

    It 'mostra a causa que o PowerShell elevado devolveu' {
        Mock Start-Process -ModuleName WinPlaybook {
            $script = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ArgumentList[4]))
            $arquivo = [regex]::Match($script, "WriteAllText\('([^']+)'").Groups[1].Value
            [IO.File]::WriteAllText($arquivo, 'O recurso OpenSSH Server não foi encontrado.')
            New-ProcessoFalso 1
        }

        { InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost' } } | Should-Throw -ExceptionMessage '*falhou como administrador*O recurso OpenSSH Server não foi encontrado.'
    }

    It 'explica quando o Windows não abre o PowerShell elevado' {
        Mock Start-Process -ModuleName WinPlaybook { throw 'A operação foi cancelada pelo usuário.' }

        { InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost' } } | Should-Throw -ExceptionMessage '*não abriu o PowerShell de administrador*cancelada pelo usuário*'
    }

    It 'mostra na etapa em andamento o progresso que o PowerShell elevado conta' {
        Mock Set-TextoDaEtapa -ModuleName WinPlaybook { }
        Mock Start-Process -ModuleName WinPlaybook {
            $script = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ArgumentList[4]))
            $arquivo = [regex]::Match($script, "WINPLAYBOOK_PROGRESS_FILE = '([^']+)'").Groups[1].Value
            $processo = [pscustomobject]@{ ExitCode = 0; HasExited = $false; Arquivo = $arquivo; Voltas = 0 }
            $processo | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { param($Milissegundos) $this.Voltas++; if ($this.Voltas -eq 1) { [IO.File]::WriteAllText($this.Arquivo, "Instalando o OpenSSH Server`n"); return $false }; $this.HasExited = $true; return $true }
            return $processo
        }

        InModuleScope WinPlaybook { Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost' }

        Should-Invoke Set-TextoDaEtapa -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Texto -eq 'Instalando o OpenSSH Server' }
    }
}
