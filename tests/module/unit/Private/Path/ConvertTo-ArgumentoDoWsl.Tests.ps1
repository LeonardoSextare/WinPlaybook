BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $pastaDoProjeto = Join-Path $TestDrive 'projeto'
    $null = New-Item -ItemType File -Path (Join-Path $pastaDoProjeto 'site.yml') -Force
    $null = New-Item -ItemType File -Path (Join-Path $pastaDoProjeto 'playbooks/site.yml') -Force
    $null = New-Item -ItemType File -Path (Join-Path $pastaDoProjeto 'vars/prod.yml') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-ArgumentoDoWsl' {
    Context 'quando o argumento não é um caminho absoluto' {
        It 'converte <Descricao>' -ForEach @(
            @{ Descricao = 'um caminho relativo que começa com .\'; Argumento = '.\site.yml'; Esperado = './site.yml' }
            @{ Descricao = 'um caminho relativo com barras invertidas'; Argumento = 'playbooks\site.yml'; Esperado = 'playbooks/site.yml' }
            @{ Descricao = 'um caminho relativo depois de @'; Argumento = '@vars\prod.yml'; Esperado = '@vars/prod.yml' }
            @{ Descricao = 'um caminho relativo depois de uma opção e de @'; Argumento = '--extra-vars=@vars\prod.yml'; Esperado = '--extra-vars=@vars/prod.yml' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Esperado
        }

        It 'mantém <Descricao> sem mudança' -ForEach @(
            @{ Descricao = 'um caminho relativo que não existe'; Argumento = 'inexistente\site.yml' }
            @{ Descricao = 'um texto com barra invertida que não é caminho'; Argumento = 'echo \n' }
            @{ Descricao = 'um argumento sem caminhos'; Argumento = '--check' }
            @{ Descricao = 'um argumento vazio'; Argumento = '' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Argumento
        }
    }

    Context 'quando o argumento é um caminho absoluto' {
        It 'converte <Descricao>' -ForEach @(
            @{ Descricao = 'o caminho'; Argumento = 'C:\repo\playbooks\site.yml'; Esperado = '/mnt/c/repo/playbooks/site.yml' }
            @{ Descricao = 'o caminho depois de uma opção'; Argumento = '--inventory=C:\repo\hosts.yml'; Esperado = '--inventory=/mnt/c/repo/hosts.yml' }
            @{ Descricao = 'o caminho depois de @'; Argumento = '@C:\repo\vars\prod.yml'; Esperado = '@/mnt/c/repo/vars/prod.yml' }
            @{ Descricao = 'o caminho depois de uma opção e de @'; Argumento = '--extra-vars=@D:\vars\prod.yml'; Esperado = '--extra-vars=@/mnt/d/vars/prod.yml' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Esperado
        }
    }
}
