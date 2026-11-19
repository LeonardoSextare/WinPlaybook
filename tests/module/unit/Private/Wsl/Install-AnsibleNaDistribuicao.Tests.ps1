BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-AnsibleNaDistribuicao' {
    Context 'quando a instalação funciona' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
        }

        It 'instala como o usuário winplaybook' {
            InModuleScope WinPlaybook { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '' }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'WinPlaybook' -and $Usuario -eq 'winplaybook'
            }
        }

        It 'instala <Descricao>' -ForEach @(
            @{ Descricao = 'a versão mais nova do ansible sem uma versão escolhida'; Versao = ''; Pacotes = @(); Esperado = 'ansible' }
            @{ Descricao = 'a versão escolhida do ansible'; Versao = '12.*'; Pacotes = @(); Esperado = 'ansible==12.*' }
            @{ Descricao = 'os pacotes Python escolhidos depois do ansible'; Versao = ''; Pacotes = @('boto3', 'netaddr>=1'); Esperado = 'ansible,boto3,netaddr>=1' }
        ) {
            InModuleScope WinPlaybook -Parameters @{ Versao = $Versao; Pacotes = $Pacotes } { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible $Versao -PacotesPython $Pacotes }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { ($Argumentos[2..($Argumentos.Count - 1)] -join ',') -eq $Esperado }
        }

        It 'grava no ambiente do Ansible o pacote que adapta o Ansible ao Windows, no lugar do módulo antigo' {
            InModuleScope WinPlaybook { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '' }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $linhas = $Argumentos[0] -split "`n"
                $arquivos = @(InModuleScope WinPlaybook { Get-ArquivoDoHookDoAnsible })
                $linhas.Count -eq $arquivos.Count -and
                $linhas[0] -eq "__init__.py $([Convert]::ToBase64String($arquivos[0].Conteudo))" -and
                $Script.Contains('"$site_packages/winplaybook_ansible/$nome"') -and $Script.Contains('import winplaybook_ansible\n'' > "$site_packages/winplaybook.pth"') -and
                $Script.Contains('rm -rf "$site_packages/winplaybook_caminhos_do_windows.py"')
            }
        }

        It 'instala o ansible-lint, o ansible-creator, o pywinrm e o argcomplete no mesmo ambiente do Ansible' {
            InModuleScope WinPlaybook { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '' }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Script.Contains('--with-executables-from "$executaveis" --with pywinrm --with argcomplete') -and $Argumentos[1] -eq 'ansible-core,ansible-lint,ansible-creator'
            }
        }

        It 'expõe os comandos <Descricao>' -ForEach @(
            @{ Descricao = 'dos pacotes Python escolhidos, pelo nome deles'; Pacotes = @('molecule', 'yamllint>=1.30', 'ruamel.yaml[jinja2]', 'pacote-local @ file:///tmp/pacote'); Esperado = 'ansible-core,ansible-lint,ansible-creator,molecule,yamllint,ruamel.yaml,pacote-local' }
            @{ Descricao = 'só do Ansible sem pacotes Python escolhidos'; Pacotes = @(); Esperado = 'ansible-core,ansible-lint,ansible-creator' }
            @{ Descricao = 'só do Ansible para um pacote pedido por URL ou caminho'; Pacotes = @('git+https://exemplo.com/pacote.git', './pacote'); Esperado = 'ansible-core,ansible-lint,ansible-creator' }
        ) {
            InModuleScope WinPlaybook -Parameters @{ Pacotes = $Pacotes } { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '' -PacotesPython $Pacotes }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Argumentos[1] -eq $Esperado }
        }
    }

    Context 'quando a instalação falha' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 1; Saida = 'No solution found when resolving dependencies' } }
        }

        It 'explica o que conferir e mostra a resposta do uv' {
            { InModuleScope WinPlaybook { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '99.*' } } | Should-Throw -ExceptionMessage '*instalar o Ansible na distribuição WSL WinPlaybook*versão do Ansible*No solution found when resolving dependencies'
        }
    }
}
