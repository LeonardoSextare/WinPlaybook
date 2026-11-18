BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ExtensaoAnsibleDoVSCode' {
    BeforeAll {
        foreach ($nome in 'redhat.ansible-26.11.0', 'redhat.ansible-26.10.0', 'redhat.vscode-yaml-2.0.0', 'redhat.ansible-sem-versao') {
            $null = New-Item -ItemType Directory -Path (Join-Path $TestDrive $nome)
        }
    }

    It 'devolve a versão e a pasta de cada extensão Ansible instalada' {
        $extensoes = @(InModuleScope WinPlaybook -Parameters @{ Pasta = $TestDrive } { Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes $Pasta } | Sort-Object -Property Versao)

        @($extensoes | ForEach-Object { $_.Versao }) | Should-BeCollection @('26.10.0', '26.11.0')
        $extensoes[1].Caminho | Should-Be (Join-Path $TestDrive 'redhat.ansible-26.11.0')
    }

    It 'não devolve nada quando a pasta das extensões não existe' {
        $extensoes = @(InModuleScope WinPlaybook -Parameters @{ Pasta = (Join-Path $TestDrive 'inexistente') } { Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes $Pasta })

        $extensoes | Should-BeCollection @()
    }
}
