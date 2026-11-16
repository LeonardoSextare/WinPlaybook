BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $pastaDoProjeto = Join-Path $TestDrive 'projeto'
    $null = New-Item -ItemType File -Path (Join-Path $pastaDoProjeto 'site.yml') -Force
    $null = New-Item -ItemType File -Path (Join-Path $pastaDoProjeto 'playbooks/site.yml') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $pastaDoProjeto 'saida') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Test-CaminhoRelativoDoWindows' {
    It 'reconhece <Descricao>' -ForEach @(
        @{ Descricao = 'um caminho que começa com .\ e existe'; Caminho = '.\site.yml' }
        @{ Descricao = 'um caminho que começa com .\ e ainda não existe'; Caminho = '.\saida\novo\inventario.json' }
        @{ Descricao = 'um caminho que começa com ..\'; Caminho = '..\outro\site.yml' }
        @{ Descricao = 'um caminho que existe'; Caminho = 'playbooks\site.yml' }
        @{ Descricao = 'um arquivo que ainda não existe numa pasta que existe'; Caminho = 'saida\inventario.json' }
        @{ Descricao = 'uma pasta com barra invertida no fim'; Caminho = 'playbooks\' }
    ) {
        $resultado = InModuleScope WinPlaybook -Parameters @{ Caminho = $Caminho; PastaAtual = $pastaDoProjeto } {
            Test-CaminhoRelativoDoWindows -Caminho $Caminho -PastaAtual $PastaAtual
        }

        $resultado | Should-BeTrue
    }

    It 'não reconhece <Descricao>' -ForEach @(
        @{ Descricao = 'um texto sem barra invertida'; Caminho = 'site.yml' }
        @{ Descricao = 'um caminho cuja pasta não existe'; Caminho = 'inexistente\site.yml' }
        @{ Descricao = 'um padrão de hosts com barra invertida'; Caminho = '~web\d+' }
        @{ Descricao = 'um texto que começa com barra invertida'; Caminho = '\d+' }
        @{ Descricao = 'um texto com barra invertida e espaço'; Caminho = 'echo \n' }
        @{ Descricao = 'um texto vazio'; Caminho = '' }
    ) {
        $resultado = InModuleScope WinPlaybook -Parameters @{ Caminho = $Caminho; PastaAtual = $pastaDoProjeto } {
            Test-CaminhoRelativoDoWindows -Caminho $Caminho -PastaAtual $PastaAtual
        }

        $resultado | Should-BeFalse
    }

    Context 'quando o texto tem caracteres que não cabem num caminho e quem chama para nos erros' {
        It 'não reconhece <Descricao>, sem erro' -ForEach @(
            @{ Descricao = 'um JSON com um caminho do Windows'; Caminho = '{"caminho": "C:\\Temp"}' }
            @{ Descricao = 'um texto com barra invertida e barra vertical'; Caminho = 'saida\a|b' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Caminho = $Caminho; PastaAtual = $pastaDoProjeto } {
                $ErrorActionPreference = 'Stop'
                Test-CaminhoRelativoDoWindows -Caminho $Caminho -PastaAtual $PastaAtual
            }

            $resultado | Should-BeFalse
        }
    }
}
