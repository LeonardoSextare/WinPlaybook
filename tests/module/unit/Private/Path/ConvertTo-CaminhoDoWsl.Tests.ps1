BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-CaminhoDoWsl' {
    Context 'quando o caminho é um caminho absoluto do Windows' {
        It 'converte <Caminho> dentro de <RaizDeMontagem> para <Esperado>' -ForEach @(
            @{ RaizDeMontagem = '/mnt/'; Caminho = 'C:\repo\site.yml'; Esperado = '/mnt/c/repo/site.yml' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = 'C:\repo\playbooks\site.yml'; Esperado = '/mnt/c/repo/playbooks/site.yml' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = 'C:/repo/playbooks/site.yml'; Esperado = '/mnt/c/repo/playbooks/site.yml' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = 'D:\Repo\Site.yml'; Esperado = '/mnt/d/Repo/Site.yml' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = 'C:\'; Esperado = '/mnt/c/' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = 'C:\my repo\[x].yml'; Esperado = '/mnt/c/my repo/[x].yml' }
            @{ RaizDeMontagem = '/mnt'; Caminho = 'C:\repo'; Esperado = '/mnt/c/repo' }
            @{ RaizDeMontagem = '/'; Caminho = 'C:\repo'; Esperado = '/c/repo' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = '\\servidor\infra\site.yml'; Esperado = '/mnt/unc/servidor/infra/site.yml' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = '\\servidor\infra'; Esperado = '/mnt/unc/servidor/infra' }
            @{ RaizDeMontagem = '/mnt/'; Caminho = '\\servidor\infra\'; Esperado = '/mnt/unc/servidor/infra' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters $_ {
                ConvertTo-CaminhoDoWsl -Caminho $Caminho -RaizDeMontagem $RaizDeMontagem
            }

            $resultado | Should-BeString $Esperado -CaseSensitive
        }
    }

    Context 'quando o caminho não é um caminho absoluto do Windows' {
        It 'recusa <_>' -ForEach @(
            'site.yml'
            'C:site.yml'
            '\\servidor'
        ) {
            {
                InModuleScope WinPlaybook -Parameters @{ Caminho = $_ } {
                    ConvertTo-CaminhoDoWsl -Caminho $Caminho -RaizDeMontagem '/mnt/'
                }
            } | Should-Throw -ExceptionMessage '*não é um caminho absoluto do Windows*'
        }
    }
}
