BeforeAll {
    $caminhoDoManifesto = Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1'
    Import-Module $caminhoDoManifesto -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDoModulo' {
    Context 'quando o módulo não está numa pasta de versão, como num clone do repositório' {
        It 'devolve a pasta do próprio módulo' {
            $esperado = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../module/WinPlaybook'))

            $resultado = InModuleScope WinPlaybook { Get-PastaDoModulo }

            $resultado | Should-Be $esperado
        }
    }

    Context 'quando o módulo está numa pasta de versão, como o instalado pela PowerShell Gallery' {
        BeforeAll {
            $pastaDaVersao = Join-Path $TestDrive 'Modules/WinPlaybook/0.0.0'
            $null = New-Item -ItemType Directory -Path $pastaDaVersao -Force
            Copy-Item -Path (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/*') -Destination $pastaDaVersao -Recurse
            $moduloInstalado = Import-Module (Join-Path $pastaDaVersao 'WinPlaybook.psd1') -PassThru -Force
        }

        AfterAll {
            Remove-Module $moduloInstalado
            Import-Module $caminhoDoManifesto -Force
        }

        It 'devolve a pasta de cima, sem a versão' {
            $resultado = & $moduloInstalado { Get-PastaDoModulo }

            $resultado | Should-Be (Join-Path $TestDrive 'Modules\WinPlaybook')
        }
    }
}
