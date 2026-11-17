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

    It 'devolve a pasta das unidades do subst' {
        $destinos = InModuleScope WinPlaybook { Get-DestinoDeUnidade }

        $destinos['W'] | Should-Be 'C:\Users\eu\infra'
        $destinos['X'] | Should-Be 'D:\outro pasta'
    }

    It 'devolve o caminho de rede das unidades mapeadas' {
        $destinos = InModuleScope WinPlaybook { Get-DestinoDeUnidade }

        $destinos['Z'] | Should-Be '\\servidor\infra\projetos'
    }

    It 'não devolve as unidades locais' {
        $destinos = InModuleScope WinPlaybook { Get-DestinoDeUnidade }

        $destinos.ContainsKey('C') | Should-BeFalse
    }
}
