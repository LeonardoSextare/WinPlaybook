BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-VersaoMaisNovaDoWinPlaybook' {
    It 'devolve a versão que a PowerShell Gallery informa' {
        Mock Invoke-WebRequest -ModuleName WinPlaybook { [pscustomobject]@{ Content = '<entry><m:properties><d:Version>0.20.0</d:Version></m:properties></entry>' } }

        $versao = InModuleScope WinPlaybook { Get-VersaoMaisNovaDoWinPlaybook }

        $versao | Should-Be ([version] '0.20.0')
        Should-Invoke Invoke-WebRequest -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Uri -like "*FindPackagesById()?id='WinPlaybook'*IsLatestVersion*" -and $TimeoutSec -eq 5 }
    }

    It 'falha quando a resposta não tem a versão' {
        Mock Invoke-WebRequest -ModuleName WinPlaybook { [pscustomobject]@{ Content = '<feed></feed>' } }

        { InModuleScope WinPlaybook { Get-VersaoMaisNovaDoWinPlaybook } } | Should-Throw
    }
}
