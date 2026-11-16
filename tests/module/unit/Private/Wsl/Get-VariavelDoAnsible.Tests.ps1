BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-VariavelDoAnsible' {
    BeforeAll {
        $parametros = @{ Distribuicao = 'Ubuntu'; RaizDeMontagem = '/mnt/'; PastaAtual = $TestDrive }
    }

    BeforeEach {
        $sufixo = [guid]::NewGuid().ToString('N').ToUpperInvariant()
        $nomeDaVariavel = "ANSIBLE_WINPLAYBOOK_TEST_$sufixo"
        $wslenvOriginal = $env:WSLENV
    }

    AfterEach {
        Remove-Item -LiteralPath "Env:$nomeDaVariavel" -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath "Env:WINPLAYBOOK_TEST_$sufixo" -ErrorAction SilentlyContinue
        $env:WSLENV = $wslenvOriginal
    }

    It 'devolve uma variável ANSIBLE_ com o caminho convertido' {
        Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'C:\infra\ansible.cfg'

        $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoAnsible -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }

        $resultado[$nomeDaVariavel] | Should-Be '/mnt/c/infra/ansible.cfg'
    }

    It 'deixa de fora uma variável que não começa com ANSIBLE_' {
        Set-Item -LiteralPath "Env:WINPLAYBOOK_TEST_$sufixo" -Value 'valor'

        $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoAnsible -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }

        $resultado.ContainsKey("WINPLAYBOOK_TEST_$sufixo") | Should-BeFalse
    }

    It 'deixa de fora uma variável ANSIBLE_ que o usuário pôs no WSLENV' {
        Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'C:\infra\ansible.cfg'
        $env:WSLENV = "OUTRA/u:$nomeDaVariavel/p"

        $resultado = InModuleScope WinPlaybook -Parameters $parametros { Get-VariavelDoAnsible -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual }

        $resultado.ContainsKey($nomeDaVariavel) | Should-BeFalse
    }
}
