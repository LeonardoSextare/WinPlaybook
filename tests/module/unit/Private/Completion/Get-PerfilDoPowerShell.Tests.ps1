BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PerfilDoPowerShell' {
    It 'devolve o profile.ps1 do PowerShell 7 e o do Windows PowerShell 5.1, em Documentos' {
        $documentos = [Environment]::GetFolderPath('MyDocuments')

        $perfis = InModuleScope WinPlaybook { Get-PerfilDoPowerShell }

        $perfis | Should-BeCollection @((Join-Path $documentos 'PowerShell\profile.ps1'), (Join-Path $documentos 'WindowsPowerShell\profile.ps1'))
    }
}
