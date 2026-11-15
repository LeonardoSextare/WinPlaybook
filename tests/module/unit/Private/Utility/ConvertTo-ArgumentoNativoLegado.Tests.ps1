BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-ArgumentoNativoLegado' {
    It 'converte <Descricao>' -ForEach @(
        @{ Descricao = 'um argumento sem caracteres especiais'; Argumento = 'site.yml'; Esperado = 'site.yml' }
        @{ Descricao = 'aspas'; Argumento = '{"saudacao": "oi mundo"}'; Esperado = '{\"saudacao\": \"oi mundo\"}' }
        @{ Descricao = 'uma barra invertida antes de aspas'; Argumento = 'a\"b'; Esperado = 'a\\\"b' }
        @{ Descricao = 'uma barra invertida no fim de um argumento com espaços'; Argumento = 'C:\My Folder\'; Esperado = 'C:\My Folder\\' }
        @{ Descricao = 'uma barra invertida no fim de um argumento sem espaços'; Argumento = 'C:\Folder\'; Esperado = 'C:\Folder\' }
        @{ Descricao = 'um argumento vazio'; Argumento = ''; Esperado = '""' }
    ) {
        $resultado = InModuleScope WinPlaybook -Parameters @{ Argumento = $Argumento } {
            ConvertTo-ArgumentoNativoLegado -Argumento $Argumento
        }

        $resultado | Should-Be $Esperado
    }

    It 'mantém a ordem de vários argumentos' {
        $resultado = InModuleScope WinPlaybook {
            ConvertTo-ArgumentoNativoLegado -Argumento '-e', '{"a": 1}', 'site.yml'
        }

        $resultado | Should-BeCollection @('-e', '{\"a\": 1}', 'site.yml')
    }
}
