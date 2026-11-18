BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-LinhaDoAutocomplete' {
    It 'chama o Register-WinPlaybookArgumentCompleter só quando ele existe' {
        $linha = InModuleScope WinPlaybook { Get-LinhaDoAutocomplete }

        $linha | Should-Be 'if (Get-Command -Name Register-WinPlaybookArgumentCompleter -ErrorAction SilentlyContinue) { Register-WinPlaybookArgumentCompleter }'
    }
}
