BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-DestinoDeUnidade' {
    BeforeAll {
        Mock subst.exe -ModuleName WinPlaybook { 'W:\: => C:\Users\eu\infra'; 'x:\: => D:\outro pasta' }
        Mock Get-PSDrive -ModuleName WinPlaybook {
            [pscustomobject]@{ Name = 'C'; DisplayRoot = $null }
            [pscustomobject]@{ Name = 'Z'; DisplayRoot = '\\servidor\infra\projetos' }
        }
    }

    Context 'quando os textos citam outras unidades' {
        It 'devolve a pasta das unidades do subst' {
            $destinos = InModuleScope WinPlaybook { Get-DestinoDeUnidade -Texto 'W:\site.yml' }

            $destinos['W'] | Should-Be 'C:\Users\eu\infra'
            $destinos['X'] | Should-Be 'D:\outro pasta'
        }

        It 'devolve o caminho de rede das unidades mapeadas' {
            $destinos = InModuleScope WinPlaybook { Get-DestinoDeUnidade -Texto 'z:\hosts.yml' }

            $destinos['Z'] | Should-Be '\\servidor\infra\projetos'
        }

        It 'não devolve as unidades locais' {
            $destinos = InModuleScope WinPlaybook { Get-DestinoDeUnidade -Texto 'W:\site.yml' }

            $destinos.ContainsKey('C') | Should-BeFalse
        }
    }

    Context 'quando os textos só citam a unidade do sistema' {
        It 'não procura as unidades' -ForEach @(
            @{ Textos = @("$env:SystemDrive\projeto", 'https://exemplo.com', '') }
            @{ Textos = @() }
        ) {
            $destinos = InModuleScope WinPlaybook -Parameters @{ Textos = $Textos } { Get-DestinoDeUnidade -Texto $Textos }

            $destinos.Count | Should-Be 0
            Should-NotInvoke subst.exe -ModuleName WinPlaybook
        }
    }
}
