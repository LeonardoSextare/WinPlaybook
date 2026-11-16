BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-Mensagem' {
    Context 'quando a interface do Windows está em português do Brasil' {
        BeforeAll {
            Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
        }

        It 'devolve a mensagem em português, com os valores nos marcadores' {
            $resultado = InModuleScope WinPlaybook { Get-Mensagem -Nome 'RaizDeMontagemDesconhecida' -Valores 'WinPlaybook', 1 }

            $resultado | Should-Be 'Não foi possível descobrir onde a distribuição WSL WinPlaybook monta as unidades do Windows (código de saída do wsl: 1).'
        }
    }

    Context 'quando a interface do Windows está em inglês' {
        BeforeAll {
            Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'en-US' }
        }

        It 'devolve a mensagem em inglês' {
            $resultado = InModuleScope WinPlaybook { Get-Mensagem -Nome 'RaizDeMontagemDesconhecida' -Valores 'WinPlaybook', 1 }

            $resultado | Should-Be 'Could not find where the WSL distribution WinPlaybook mounts the Windows drives (wsl exit code: 1).'
        }
    }

    Context 'quando a interface do Windows está num idioma sem mensagens' {
        It 'devolve a mensagem em inglês para <Descricao>' -ForEach @(
            @{ Descricao = 'o espanhol'; Cultura = 'es-ES' }
            @{ Descricao = 'o português de Portugal'; Cultura = 'pt-PT' }
            @{ Descricao = 'a cultura invariável'; Cultura = '' }
        ) {
            Mock Get-CulturaDaInterface -ModuleName WinPlaybook { $Cultura }

            $resultado = InModuleScope WinPlaybook { Get-Mensagem -Nome 'InformeOComando' }

            $resultado | Should-Be 'Specify the command to run in the WSL distribution, for example: Invoke-WinPlaybook ansible --version'
        }
    }
}
