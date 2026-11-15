BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'New-ShimDeComando' {
    BeforeAll {
        $caminhoDoModelo = Join-Path $TestDrive 'modelo.exe'
        Set-Content -LiteralPath $caminhoDoModelo -Value 'shim modelo'
        Mock Get-CaminhoDoModeloDeShim -ModuleName WinPlaybook { $caminhoDoModelo }
    }

    Context 'quando um shim é criado' {
        BeforeAll {
            $pastaDosShims = Join-Path $TestDrive 'shims'
            $null = New-Item -ItemType Directory -Path $pastaDosShims

            InModuleScope WinPlaybook -Parameters @{ Pasta = $pastaDosShims } {
                New-ShimDeComando -Nome 'ansible-playbook' -Pasta $Pasta -CaminhoDoPowerShell 'C:\PowerShell\pwsh.exe'
            }
        }

        It 'grava um script que executa o comando pelo módulo' {
            $conteudo = Get-Content -LiteralPath (Join-Path $pastaDosShims 'ansible-playbook.ps1')

            $conteudo | Should-Be "WinPlaybook\Invoke-WinPlaybook 'ansible-playbook' @args; exit `$LASTEXITCODE"
        }

        It 'copia o shim empacotado como o executável' {
            $conteudo = Get-Content -LiteralPath (Join-Path $pastaDosShims 'ansible-playbook.exe')

            $conteudo | Should-Be 'shim modelo'
        }

        It 'aponta o executável para o script pelo PowerShell escolhido' {
            $caminhoDoScript = Join-Path $pastaDosShims 'ansible-playbook.ps1'

            $conteudo = Get-Content -LiteralPath (Join-Path $pastaDosShims 'ansible-playbook.shim') -Encoding UTF8

            $conteudo | Should-BeCollection @(
                'path = C:\PowerShell\pwsh.exe'
                "args = -NoProfile -ExecutionPolicy Bypass -File `"$caminhoDoScript`""
            )
        }
    }

    Context 'quando a pasta tem caracteres não ASCII' {
        BeforeAll {
            $nomeDaPasta = "pasta-a$([char]0x00E7)$([char]0x00E3)o"
            $pastaDosShims = Join-Path $TestDrive $nomeDaPasta
            $null = New-Item -ItemType Directory -Path $pastaDosShims

            InModuleScope WinPlaybook -Parameters @{ Pasta = $pastaDosShims } {
                New-ShimDeComando -Nome 'ansible' -Pasta $Pasta -CaminhoDoPowerShell 'C:\PowerShell\pwsh.exe'
            }
        }

        It 'grava a configuração do shim em UTF-8' {
            $bytes = [IO.File]::ReadAllBytes((Join-Path $pastaDosShims 'ansible.shim'))

            [Text.Encoding]::UTF8.GetString($bytes) | Should-BeLikeString "*$nomeDaPasta*"
        }
    }
}
