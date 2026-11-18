BeforeAll {
    . (Join-Path $PSScriptRoot '../../../helpers/VSCode.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-PatchDaExtensaoAnsible' {
    Context 'quando a extensão tem as correções' {
        BeforeAll {
            $extensao = New-ExtensaoAnsibleFalsa -PastaDasExtensoes $TestDrive -Versao '26.11.0'
            $pastaDoServidor = Join-Path $extensao 'packages\ansible-language-server\dist'
            $originais = @{}
            foreach ($arquivo in Get-ChildItem -LiteralPath $pastaDoServidor -Recurse -File) {
                $originais[$arquivo.FullName] = [IO.File]::ReadAllText($arquivo.FullName)
            }
            InModuleScope WinPlaybook -Parameters @{ Caminho = $extensao } {
                Install-PatchDaExtensaoAnsible -Caminho $Caminho -Trocas (Get-PatchDaExtensaoAnsible)['26.11.0'] -Versao '26.11.0'
                Remove-PatchDaExtensaoAnsible -Caminho $Caminho
            }
        }

        It 'devolve os arquivos originais' {
            $devolvidos = @($originais.Keys | Where-Object { [IO.File]::ReadAllText($_) -eq $originais[$_] })

            $devolvidos.Count | Should-Be $originais.Count
        }

        It 'apaga as cópias dos originais' {
            @(Get-ChildItem -LiteralPath $extensao -Filter '*.winplaybook-original' -Recurse) | Should-BeCollection @()
        }
    }

    It 'não faz nada numa pasta sem o language server' {
        $pasta = Join-Path $TestDrive 'redhat.ansible-1.0.0'
        $null = New-Item -ItemType Directory -Path $pasta

        InModuleScope WinPlaybook -Parameters @{ Caminho = $pasta } { Remove-PatchDaExtensaoAnsible -Caminho $Caminho }

        @(Get-ChildItem -LiteralPath $pasta -Recurse) | Should-BeCollection @()
    }
}
