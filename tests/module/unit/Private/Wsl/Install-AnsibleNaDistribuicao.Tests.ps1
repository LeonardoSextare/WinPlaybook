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

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { ($Argumentos[1..($Argumentos.Count - 1)] -join ',') -eq $Esperado }
        }

        It 'grava no ambiente do Ansible o módulo que aceita caminhos do Windows' {
            InModuleScope WinPlaybook { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '' }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Argumentos[0])) -eq (InModuleScope WinPlaybook { Get-ScriptDosCaminhosDoWindows }) -and
                $Script.Contains('"$site_packages/winplaybook_caminhos_do_windows.py"') -and $Script.Contains('import winplaybook_caminhos_do_windows\n'' > "$site_packages/winplaybook.pth"')
            }
        }

        It 'instala o ansible-lint e o pywinrm no mesmo ambiente do Ansible' {
            InModuleScope WinPlaybook { Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '' }

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Script.Contains('--with-executables-from ansible-core,ansible-lint --with pywinrm')
            }
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
