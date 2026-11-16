BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ArgumentoDoShim' {
    BeforeAll {
        $caminhoDoShim = 'C:\shims\ansible-playbook.ps1'
        $argumentosSeparados = @('--inventory=C', '\infra\hosts.yml', 'site.yml')
    }

    Context 'quando o PowerShell foi aberto com -File para executar o shim do comando' {
        BeforeAll {
            Mock Get-ArgumentoDoProcesso -ModuleName WinPlaybook {
                'pwsh.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'C:\shims\ansible-playbook.ps1', '--inventory=C:\infra\hosts.yml', 'site.yml'
            }
        }

        It 'devolve os argumentos do processo depois do script' {
            $resultado = InModuleScope WinPlaybook -Parameters @{ CaminhoDoShim = $caminhoDoShim; Argumentos = $argumentosSeparados } {
                Get-ArgumentoDoShim -Comando 'ansible-playbook' -Argumentos $Argumentos -CaminhoDoChamador $CaminhoDoShim
            }

            $resultado | Should-BeCollection @('--inventory=C:\infra\hosts.yml', 'site.yml')
        }

        It 'reconhece o script com outra caixa no caminho' {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumentos = $argumentosSeparados } {
                Get-ArgumentoDoShim -Comando 'ansible-playbook' -Argumentos $Argumentos -CaminhoDoChamador 'c:\SHIMS\ansible-playbook.ps1'
            }

            $resultado | Should-BeCollection @('--inventory=C:\infra\hosts.yml', 'site.yml')
        }
    }

    Context 'quando o PowerShell foi aberto com -File para executar o shim sem argumentos' {
        BeforeAll {
            Mock Get-ArgumentoDoProcesso -ModuleName WinPlaybook {
                'pwsh.exe', '-NoProfile', '-File', 'C:\shims\ansible-playbook.ps1'
            }
        }

        It 'não devolve argumentos' {
            $resultado = InModuleScope WinPlaybook -Parameters @{ CaminhoDoShim = $caminhoDoShim } {
                Get-ArgumentoDoShim -Comando 'ansible-playbook' -CaminhoDoChamador $CaminhoDoShim
            }

            @($resultado).Count | Should-Be 0
        }
    }

    Context 'quando o PowerShell foi aberto com -File para executar outro script' {
        BeforeAll {
            Mock Get-ArgumentoDoProcesso -ModuleName WinPlaybook {
                'pwsh.exe', '-File', 'C:\scripts\deploy.ps1', '-Ambiente', 'prod'
            }
        }

        It 'devolve os argumentos recebidos quando o chamador é <Descricao>' -ForEach @(
            @{ Descricao = 'esse outro script'; CaminhoDoChamador = 'C:\scripts\deploy.ps1' }
            @{ Descricao = 'o shim do comando, chamado de dentro dele'; CaminhoDoChamador = 'C:\shims\ansible-playbook.ps1' }
            @{ Descricao = 'o terminal'; CaminhoDoChamador = '' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ CaminhoDoChamador = $CaminhoDoChamador; Argumentos = $argumentosSeparados } {
                Get-ArgumentoDoShim -Comando 'ansible-playbook' -Argumentos $Argumentos -CaminhoDoChamador $CaminhoDoChamador
            }

            $resultado | Should-BeCollection $argumentosSeparados
        }
    }

    Context 'quando o caminho do shim aparece no processo sem o -File antes dele' {
        BeforeAll {
            Mock Get-ArgumentoDoProcesso -ModuleName WinPlaybook {
                'pwsh.exe', '-Command', 'C:\shims\ansible-playbook.ps1', '--inventory=C:\infra\hosts.yml'
            }
        }

        It 'devolve os argumentos recebidos' {
            $resultado = InModuleScope WinPlaybook -Parameters @{ CaminhoDoShim = $caminhoDoShim; Argumentos = $argumentosSeparados } {
                Get-ArgumentoDoShim -Comando 'ansible-playbook' -Argumentos $Argumentos -CaminhoDoChamador $CaminhoDoShim
            }

            $resultado | Should-BeCollection $argumentosSeparados
        }
    }
}
