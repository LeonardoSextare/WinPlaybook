BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-MontagemNecessaria' {
    It 'monta o compartilhamento de <Descricao>' -ForEach @(
        @{ Descricao = 'um caminho'; Texto = '/mnt/unc/servidor/infra/site.yml' }
        @{ Descricao = 'uma pasta atual na raiz dele'; Texto = '/mnt/unc/servidor/infra' }
        @{ Descricao = 'um caminho depois de uma opção'; Texto = '--inventory=/mnt/unc/servidor/infra/hosts.yml' }
        @{ Descricao = 'uma lista de caminhos'; Texto = '/mnt/c/roles:/mnt/unc/servidor/infra/roles' }
    ) {
        $montagens = @(InModuleScope WinPlaybook -Parameters @{ Texto = $Texto } {
                Get-MontagemNecessaria -Texto $Texto -RaizDeMontagem '/mnt/'
            })

        $montagens.Count | Should-Be 1
        $montagens[0].Origem | Should-Be '\\servidor\infra'
        $montagens[0].PontoDeMontagem | Should-Be '/mnt/unc/servidor/infra'
    }

    It 'não monta <Descricao>' -ForEach @(
        @{ Descricao = 'uma unidade que o WSL monta sozinho'; Texto = '/mnt/c/infra/site.yml' }
        @{ Descricao = 'um caminho do disco do Linux'; Texto = '/home/winplaybook/site.yml' }
        @{ Descricao = 'um argumento que não é caminho'; Texto = '--check' }
    ) {
        $montagens = @(InModuleScope WinPlaybook -Parameters @{ Texto = $Texto } {
                Get-MontagemNecessaria -Texto $Texto -RaizDeMontagem '/mnt/'
            })

        $montagens.Count | Should-Be 0
    }

    It 'monta cada compartilhamento uma vez só' {
        $montagens = @(InModuleScope WinPlaybook {
                Get-MontagemNecessaria -Texto '/mnt/unc/servidor/infra/a', '/mnt/unc/servidor/infra/b', '/mnt/unc/servidor/outro' -RaizDeMontagem '/mnt/'
            })

        $montagens.Count | Should-Be 2
    }
}
