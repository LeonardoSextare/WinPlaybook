BeforeAll {
    . (Join-Path $PSScriptRoot '../../helpers/VSCode.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Enable-WinPlaybookVSCodeExtension' {
    BeforeEach {
        $pastaDasExtensoes = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $pastaDasExtensoes
        Mock Get-PastaDasExtensoesDoVSCode -ModuleName WinPlaybook { $pastaDasExtensoes }
    }

    Context 'quando a versão mais nova da extensão foi testada' {
        BeforeEach {
            $null = New-ExtensaoAnsibleFalsa -PastaDasExtensoes $pastaDasExtensoes -Versao '26.9.0' -SemTrechos
            $extensao = New-ExtensaoAnsibleFalsa -PastaDasExtensoes $pastaDasExtensoes -Versao '26.11.0'
        }

        It 'corrige a versão mais nova' {
            $null = Enable-WinPlaybookVSCodeExtension

            @(Get-ChildItem -LiteralPath $extensao -Filter '*.winplaybook-original' -Recurse).Count | Should-BeGreaterThan 0
        }

        It 'devolve a versão, a pasta e a configuração que o settings.json precisa ter com -PassThru' {
            $resultado = Enable-WinPlaybookVSCodeExtension -PassThru

            $resultado.Version | Should-Be '26.11.0'
            $resultado.Path | Should-Be $extensao
            @($resultado.RequiredSettings['security.allowedUNCHosts']) | Should-BeCollection @('wsl.localhost')
        }

        It 'não altera nada com -WhatIf' {
            $null = Enable-WinPlaybookVSCodeExtension -WhatIf

            @(Get-ChildItem -LiteralPath $extensao -Filter '*.winplaybook-original' -Recurse) | Should-BeCollection @()
        }
    }

    It 'explica como instalar a extensão quando ela não está instalada' {
        { Enable-WinPlaybookVSCodeExtension } | Should-Throw -ExceptionMessage '*não foi encontrada*code --install-extension redhat.ansible@26.11.0'
    }

    It 'explica como voltar à versão testada quando a mais nova ainda não foi testada' {
        $null = New-ExtensaoAnsibleFalsa -PastaDasExtensoes $pastaDasExtensoes -Versao '26.11.0'
        $null = New-ExtensaoAnsibleFalsa -PastaDasExtensoes $pastaDasExtensoes -Versao '27.1.0' -SemTrechos

        { Enable-WinPlaybookVSCodeExtension } | Should-Throw -ExceptionMessage '*versão 27.1.0*ainda não testou*code --install-extension redhat.ansible@26.11.0*'
    }
}
