BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $pastaDoProjeto = Join-Path $TestDrive 'projeto'
    $null = New-Item -ItemType Directory -Path (Join-Path $pastaDoProjeto 'roles') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-ValorDoWsl' {
    It 'converte <Descricao>' -ForEach @(
        @{ Descricao = 'um caminho absoluto'; Valor = 'C:\infra\ansible.cfg'; Esperado = '/mnt/c/infra/ansible.cfg' }
        @{ Descricao = 'um caminho relativo que começa com .\'; Valor = '.\ansible.cfg'; Esperado = './ansible.cfg' }
        @{ Descricao = 'um caminho do disco do Linux'; Valor = '\\wsl.localhost\Ubuntu\home\eu\.vault'; Esperado = '/home/eu/.vault' }
        @{ Descricao = 'uma lista do Windows, com ;, numa lista do Linux, com :'; Valor = 'C:\roles;D:\mais\roles'; Esperado = '/mnt/c/roles:/mnt/d/mais/roles' }
        @{ Descricao = 'uma lista do Windows com um caminho relativo'; Valor = 'roles\extra;C:\roles'; Esperado = 'roles/extra:/mnt/c/roles' }
        @{ Descricao = 'uma lista com vírgulas, mantendo as vírgulas'; Valor = 'C:\inventario\a.yml,C:\inventario\b.yml'; Esperado = '/mnt/c/inventario/a.yml,/mnt/c/inventario/b.yml' }
    ) {
        $resultado = InModuleScope WinPlaybook -Parameters @{ Valor = $Valor; PastaAtual = $pastaDoProjeto } {
            ConvertTo-ValorDoWsl -Valor $Valor -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
        }

        $resultado | Should-Be $Esperado
    }

    It 'mantém <Descricao> sem mudança' -ForEach @(
        @{ Descricao = 'um valor sem caminhos'; Valor = 'yaml' }
        @{ Descricao = 'uma lista com vírgulas sem caminhos'; Valor = 'timer,profile_tasks' }
        @{ Descricao = 'uma lista com ; sem caminhos do Windows'; Valor = 'a;b' }
        @{ Descricao = 'um caminho do Linux'; Valor = '~/.ansible/roles:/etc/ansible/roles' }
        @{ Descricao = 'um valor vazio'; Valor = '' }
    ) {
        $resultado = InModuleScope WinPlaybook -Parameters @{ Valor = $Valor; PastaAtual = $pastaDoProjeto } {
            ConvertTo-ValorDoWsl -Valor $Valor -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
        }

        $resultado | Should-Be $Valor
    }
}
