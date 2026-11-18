BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $trocasDaVersao = InModuleScope WinPlaybook { (Get-PatchDaExtensaoAnsible)['26.11.0'] }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '../../../helpers/VSCode.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    $trocas = InModuleScope WinPlaybook { (Get-PatchDaExtensaoAnsible)['26.11.0'] }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-PatchDaExtensaoAnsible' {
    Context 'quando a extensão tem os trechos da versão testada' {
        BeforeAll {
            $extensao = New-ExtensaoAnsibleFalsa -PastaDasExtensoes (Join-Path $TestDrive 'com-trechos') -Versao '26.11.0'
            $pastaDoServidor = Join-Path $extensao 'packages\ansible-language-server\dist'
            $originais = @{}
            foreach ($arquivo in Get-ChildItem -LiteralPath $pastaDoServidor -Recurse -File) {
                $originais[$arquivo.FullName] = [IO.File]::ReadAllText($arquivo.FullName)
            }
            InModuleScope WinPlaybook -Parameters @{ Caminho = $extensao; Trocas = $trocas } { Install-PatchDaExtensaoAnsible -Caminho $Caminho -Trocas $Trocas -Versao '26.11.0' }
            InModuleScope WinPlaybook -Parameters @{ Caminho = $extensao; Trocas = $trocas } { Install-PatchDaExtensaoAnsible -Caminho $Caminho -Trocas $Trocas -Versao '26.11.0' }
        }

        It 'troca o trecho <De> em <Arquivo>' -ForEach $trocasDaVersao {
            $texto = [IO.File]::ReadAllText((Join-Path $pastaDoServidor $Arquivo))

            $texto.Contains($Para) | Should-BeTrue
        }

        It 'guarda o original de cada arquivo, mesmo aplicado duas vezes' {
            $guardados = @($originais.Keys | Where-Object { [IO.File]::ReadAllText("$_.winplaybook-original") -eq $originais[$_] })

            $guardados.Count | Should-Be $originais.Count
        }
    }

    Context 'quando a extensão não tem os trechos esperados' {
        BeforeAll {
            $extensao = New-ExtensaoAnsibleFalsa -PastaDasExtensoes (Join-Path $TestDrive 'sem-trechos') -Versao '26.11.0' -SemTrechos
        }

        It 'falha, explica como reinstalar a extensão e não altera nada' {
            { InModuleScope WinPlaybook -Parameters @{ Caminho = $extensao; Trocas = $trocas } { Install-PatchDaExtensaoAnsible -Caminho $Caminho -Trocas $Trocas -Versao '26.11.0' } } | Should-Throw -ExceptionMessage '*não tem o trecho esperado da versão 26.11.0*code --install-extension redhat.ansible@26.11.0 --force'

            @(Get-ChildItem -LiteralPath $extensao -Filter '*.winplaybook-original' -Recurse) | Should-BeCollection @()
        }
    }
}
