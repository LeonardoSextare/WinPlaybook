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
            @{ Descricao = 'um caminho relativo que começa com .\ e ainda não existe'; Argumento = '.\saida\inventario.json'; Esperado = './saida/inventario.json' }
            @{ Descricao = 'um caminho relativo com barras invertidas'; Argumento = 'playbooks\site.yml'; Esperado = 'playbooks/site.yml' }
            @{ Descricao = 'um arquivo que ainda não existe numa pasta que existe'; Argumento = 'playbooks\novo.yml'; Esperado = 'playbooks/novo.yml' }
            @{ Descricao = 'um arquivo que ainda não existe depois de uma opção'; Argumento = '--output=playbooks\novo.json'; Esperado = '--output=playbooks/novo.json' }
            @{ Descricao = 'um caminho relativo depois de @'; Argumento = '@vars\prod.yml'; Esperado = '@vars/prod.yml' }
            @{ Descricao = 'um caminho relativo depois de uma opção e de @'; Argumento = '--extra-vars=@vars\prod.yml'; Esperado = '--extra-vars=@vars/prod.yml' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Esperado
        }

        It 'mantém <Descricao> sem mudança' -ForEach @(
            @{ Descricao = 'um caminho relativo cuja pasta não existe'; Argumento = 'inexistente\site.yml' }
            @{ Descricao = 'um texto com barra invertida que não é caminho'; Argumento = 'echo \n' }
            @{ Descricao = 'um padrão de hosts com barra invertida'; Argumento = '~web\d+' }
            @{ Descricao = 'um argumento sem caminhos'; Argumento = '--check' }
            @{ Descricao = 'um argumento vazio'; Argumento = '' }
            @{ Descricao = 'um argumento com várias linhas'; Argumento = "primeira linha`nsegunda linha" }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Argumento
        }
    }

    Context 'quando o argumento tem caracteres que não cabem num caminho e quem chama para nos erros' {
        It 'mantém <Descricao> sem mudança e sem erro' -ForEach @(
            @{ Descricao = 'um JSON com um caminho do Windows'; Argumento = '{"caminho": "C:\\Temp"}' }
            @{ Descricao = 'um texto com barra invertida e barra vertical'; Argumento = 'a\b|c' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                $ErrorActionPreference = 'Stop'
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
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
            @{ Descricao = 'o caminho no formato de uma URI, com uma barra antes da unidade'; Argumento = '/C:/repo/playbooks/site.yml'; Esperado = '/mnt/c/repo/playbooks/site.yml' }
            @{ Descricao = 'o caminho no formato de uma URI depois de uma opção'; Argumento = '--config-file=/c:/repo/.ansible-lint'; Esperado = '--config-file=/mnt/c/repo/.ansible-lint' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Esperado
        }
    }

    Context 'quando o argumento é um caminho do disco do Linux' {
        It 'converte <Descricao>' -ForEach @(
            @{ Descricao = 'o caminho \\wsl.localhost da distribuição'; Argumento = '\\wsl.localhost\Ubuntu\home\eu\site.yml'; Esperado = '/home/eu/site.yml' }
            @{ Descricao = 'o caminho \\wsl$ da distribuição'; Argumento = '\\wsl$\Ubuntu\home\eu\site.yml'; Esperado = '/home/eu/site.yml' }
            @{ Descricao = 'o caminho com outra caixa'; Argumento = '\\WSL.LOCALHOST\ubuntu\home\eu\site.yml'; Esperado = '/home/eu/site.yml' }
            @{ Descricao = 'o caminho depois de uma opção'; Argumento = '--inventory=\\wsl.localhost\Ubuntu\home\eu\hosts.yml'; Esperado = '--inventory=/home/eu/hosts.yml' }
            @{ Descricao = 'o caminho depois de @'; Argumento = '@\\wsl.localhost\Ubuntu\home\eu\vars.yml'; Esperado = '@/home/eu/vars.yml' }
            @{ Descricao = 'o caminho de outro computador da rede'; Argumento = '\\servidor\infra\site.yml'; Esperado = '/mnt/unc/servidor/infra/site.yml' }
            @{ Descricao = 'o caminho de rede depois de uma opção'; Argumento = '--inventory=\\servidor\infra\hosts.yml'; Esperado = '--inventory=/mnt/unc/servidor/infra/hosts.yml' }
            @{ Descricao = 'o caminho no valor de um chave=valor'; Argumento = 'pasta=C:\infra\files'; Esperado = 'pasta=/mnt/c/infra/files' }
            @{ Descricao = 'os caminhos nos valores de vários chave=valor'; Argumento = 'src=C:\infra\a.txt dest=/tmp/a.txt backup=D:\copias'; Esperado = 'src=/mnt/c/infra/a.txt dest=/tmp/a.txt backup=/mnt/d/copias' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Esperado
        }

        It 'converte <Descricao> para a pasta real' -ForEach @(
            @{ Descricao = 'o caminho numa unidade do subst'; Argumento = 'W:\site.yml'; Esperado = '/mnt/c/infra/site.yml' }
            @{ Descricao = 'o caminho numa unidade de rede'; Argumento = '--inventory=Z:\hosts.yml'; Esperado = '--inventory=/mnt/unc/servidor/infra/hosts.yml' }
            @{ Descricao = 'a raiz de uma unidade do subst'; Argumento = 'w:\'; Esperado = '/mnt/c/infra/' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual -DestinoDeUnidade @{ W = 'C:\infra'; Z = '\\servidor\infra' }
            }

            $resultado | Should-Be $Esperado
        }

        It 'mantém <Descricao> sem mudança' -ForEach @(
            @{ Descricao = 'o caminho de outra distribuição'; Argumento = '\\wsl.localhost\Debian\home\eu\site.yml' }
            @{ Descricao = 'o caminho de outra distribuição pelo wsl$'; Argumento = '\\wsl$\Debian\home\eu\site.yml' }
            @{ Descricao = 'um named pipe do Windows'; Argumento = '\\.\pipe\openssh-ssh-agent' }
            @{ Descricao = 'um caminho de dispositivo do Windows'; Argumento = '\\?\C:\infra\site.yml' }
        ) {
            $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento; PastaAtual = $pastaDoProjeto } {
                ConvertTo-ArgumentoDoWsl -Argumento $Argumento -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual $PastaAtual
            }

            $resultado | Should-Be $Argumento
        }
    }
}