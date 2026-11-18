BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Processo.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Shim.ps1')
    . (Join-Path $PSScriptRoot '../helpers/VSCode.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Wsl.ps1')
    Import-Module (Join-Path $PSScriptRoot '../../../module/WinPlaybook/WinPlaybook.psd1') -Force

    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste

    $localAppDataOriginal = $env:LOCALAPPDATA
    $extensaoGuardada = Get-ExtensaoAnsibleDeTeste -Versao '26.11.0'
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'

    $caminhoDoExecutavel = New-ExecutavelDeShimDeTeste -Pasta (Join-Path $TestDrive 'executavel')
    $pastaDosShims = Join-Path $TestDrive 'shims'
    $null = New-Item -ItemType Directory -Path $pastaDosShims
    $parametrosDosShims = @{ Pasta = $pastaDosShims; CaminhoDoPowerShell = (Get-Process -Id $PID).Path; Distribuicao = $nomeDaDistribuicao; CaminhoDoExecutavel = $caminhoDoExecutavel }
    InModuleScope WinPlaybook -Parameters $parametrosDosShims {
        Save-Configuracao -Configuracao @{ WslDistribution = $Distribuicao; WslMountRoot = (Get-RaizDeMontagemDoWsl -Distribuicao $Distribuicao) }
        foreach ($comando in Get-ComandoDoAnsible -Distribuicao $Distribuicao) {
            New-ShimDeComando -Nome $comando -Pasta $Pasta -CaminhoDoPowerShell $CaminhoDoPowerShell -PastaDoModulo (Get-PastaDoModulo) -CaminhoDoExecutavel $CaminhoDoExecutavel
        }
    }

    $projeto = Join-Path $TestDrive 'projeto'
    $null = New-Item -ItemType Directory -Path $projeto
    $linhas = @(
        '- hosts: localhost'
        '  tasks:'
        '    - ansible.builtin.debug:'
        '        msg: oi'
        '    - community.general.ini_file:'
        '        path: /tmp/configuracao.ini'
        '        section: secao'
        '        option: opcao'
        '        value: valor'
    )
    [IO.File]::WriteAllText((Join-Path $projeto 'site.yml'), ($linhas -join "`n") + "`n")
}

AfterAll {
    Remove-Module WinPlaybook
    $env:LOCALAPPDATA = $localAppDataOriginal
}

Describe 'Extensão Ansible do VS Code' {
    Context 'quando a extensão tem as correções do WinPlaybook' {
        BeforeAll {
            $extensao = Join-Path $TestDrive 'extensoes\redhat.ansible-26.11.0'
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $extensao)
            Copy-Item -LiteralPath $extensaoGuardada -Destination $extensao -Recurse
            InModuleScope WinPlaybook -Parameters @{ Caminho = $extensao } {
                Install-PatchDaExtensaoAnsible -Caminho $Caminho -Trocas (Get-PatchDaExtensaoAnsible)['26.11.0'] -Versao '26.11.0'
            }
            $registros = @(Invoke-ClienteLsp -PastaDaExtensao $extensao -PastaDoProjeto $projeto -PastaDosShims $pastaDosShims)
        }

        It 'mostra o hover de <Modulo>' -ForEach @(
            @{ Modulo = 'ansible.builtin.debug'; Trecho = '*Print statements*' }
            @{ Modulo = 'community.general.ini_file'; Trecho = '*INI*' }
        ) {
            $hover = $registros | Where-Object { $_.tipo -eq 'hover' -and $_.modulo -eq $Modulo }

            $hover.texto | Should-BeLikeString $Trecho
        }

        It 'valida o playbook com o ansible-lint' {
            $diagnosticos = $registros | Where-Object { $_.tipo -eq 'diagnosticos' }

            @($diagnosticos.mensagens) -join "`n" | Should-BeLikeString '*name*'
            @($diagnosticos.mensagens) -join "`n" | Should-NotBeLikeString '*No such file*'
        }
    }

    Context 'quando a extensão não tem as correções' {
        BeforeAll {
            $registrosSemCorrecoes = @(Invoke-ClienteLsp -PastaDaExtensao $extensaoGuardada -PastaDoProjeto $projeto -PastaDosShims $pastaDosShims)
        }

        It 'não mostra a documentação dos módulos' {
            $hover = $registrosSemCorrecoes | Where-Object { $_.tipo -eq 'hover' -and $_.modulo -eq 'ansible.builtin.debug' }

            $hover.texto | Should-Be ''
        }
    }
}
