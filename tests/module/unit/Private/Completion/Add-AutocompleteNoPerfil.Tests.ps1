BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $linha = InModuleScope WinPlaybook { Get-LinhaDoAutocomplete }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Add-AutocompleteNoPerfil' {
    BeforeEach {
        $perfil = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N'))/PowerShell/profile.ps1"
    }

    It 'cria o perfil que não existe, só com a linha' {
        InModuleScope WinPlaybook -Parameters @{ Perfil = $perfil } { Add-AutocompleteNoPerfil -Perfil $Perfil }

        @(Get-Content -LiteralPath $perfil) | Should-BeCollection @($linha)
    }

    It 'acrescenta a linha depois do que o perfil já tem, mesmo sem quebra de linha no fim' {
        $null = New-Item -ItemType File -Path $perfil -Force
        [IO.File]::WriteAllText($perfil, 'Set-Alias ll Get-ChildItem')

        InModuleScope WinPlaybook -Parameters @{ Perfil = $perfil } { Add-AutocompleteNoPerfil -Perfil $Perfil }

        @(Get-Content -LiteralPath $perfil) | Should-BeCollection @('Set-Alias ll Get-ChildItem', $linha)
    }

    It 'não repete a linha num perfil que já a tem' {
        InModuleScope WinPlaybook -Parameters @{ Perfil = $perfil } { Add-AutocompleteNoPerfil -Perfil $Perfil }

        InModuleScope WinPlaybook -Parameters @{ Perfil = $perfil } { Add-AutocompleteNoPerfil -Perfil $Perfil }

        @(Get-Content -LiteralPath $perfil) | Should-BeCollection @($linha)
    }
}
