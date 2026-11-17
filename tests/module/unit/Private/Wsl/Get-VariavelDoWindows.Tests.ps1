BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-VariavelDoWindows' {
    BeforeAll {
        $parametros = @{ Distribuicao = 'Ubuntu'; RaizDeMontagem = '/mnt/'; PastaAtual = $TestDrive }
    }

    BeforeEach {
        $sufixo = [guid]::NewGuid().ToString('N').ToUpperInvariant()
        $nomeDaVariavel = "WINPLAYBOOK_TEST_$sufixo"
        $wslenvOriginal = $env:WSLENV
    }

    AfterEach {
        Remove-Item -LiteralPath "Env:$nomeDaVariavel" -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath "Env:ANSIBLE_$nomeDaVariavel" -ErrorAction SilentlyContinue
        $env:WSLENV = $wslenvOriginal
    }

    It 'devolve uma variável ANSIBLE_ com o caminho convertido' {
        Set-Item -LiteralPath "Env:ANSIBLE_$nomeDaVariavel" -Value 'C:\infra\ansible.cfg'

        $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoWindows -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }

        $resultado["ANSIBLE_$nomeDaVariavel"] | Should-Be '/mnt/c/infra/ansible.cfg'
    }

    It 'devolve uma variável que não é do Ansible' {
        Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'http://proxy.empresa:8080'

        $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoWindows -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }

        $resultado[$nomeDaVariavel] | Should-Be 'http://proxy.empresa:8080'
    }

    It 'deixa de fora <_>, que a distribuição define do próprio jeito' -ForEach 'Path', 'TEMP', 'PYTHONPATH', 'LC_ALL', 'WSL_UTF8' {
        $nome = $_
        $valorOriginal = [Environment]::GetEnvironmentVariable($nome)
        Set-Item -LiteralPath "Env:$nome" -Value 'C:\valor\do\windows'
        try {
            $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoWindows -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }
        }
        finally {
            Remove-Item -LiteralPath "Env:$nome" -ErrorAction SilentlyContinue
            if ($null -ne $valorOriginal) {
                Set-Item -LiteralPath "Env:$nome" -Value $valorOriginal
            }
        }

        $resultado.ContainsKey($nome) | Should-BeFalse
    }

    It 'deixa de fora uma variável com nome que o Linux não aceita' {
        $nomeInvalido = "$nomeDaVariavel(x86)"
        Set-Item -LiteralPath "Env:$nomeInvalido" -Value 'C:\Arquivos'
        try {
            $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoWindows -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }
        }
        finally {
            Remove-Item -LiteralPath "Env:$nomeInvalido" -ErrorAction SilentlyContinue
        }

        $resultado.ContainsKey($nomeInvalido) | Should-BeFalse
    }

    It 'deixa de fora uma variável que o usuário pôs no WSLENV' {
        Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'C:\infra\ansible.cfg'
        $env:WSLENV = "OUTRA/u:$nomeDaVariavel/p"

        $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoWindows -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }

        $resultado.ContainsKey($nomeDaVariavel) | Should-BeFalse
    }
}
