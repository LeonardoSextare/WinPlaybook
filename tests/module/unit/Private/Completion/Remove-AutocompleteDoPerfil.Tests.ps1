BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    $linha = InModuleScope WinPlaybook { Get-LinhaDoAutocomplete }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-AutocompleteDoPerfil' {
    BeforeEach {
        $perfil = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N'))/profile.ps1"
        $null = New-Item -ItemType File -Path $perfil -Force
    }

    It 'tira a linha e mantém as outras' {
        Set-Content -LiteralPath $perfil -Value 'Set-Alias ll Get-ChildItem', $linha, 'Import-Module posh-git'

        InModuleScope WinPlaybook -Parameters @{ Perfil = $perfil } { Remove-AutocompleteDoPerfil -Perfil $Perfil }

        @(Get-Content -LiteralPath $perfil) | Should-BeCollection @('Set-Alias ll Get-ChildItem', 'Import-Module posh-git')
    }

    It 'apaga o perfil que fica vazio sem a linha' {
        Set-Content -LiteralPath $perfil -Value $linha

        InModuleScope WinPlaybook -Parameters @{ Perfil = $perfil } { Remove-AutocompleteDoPerfil -Perfil $Perfil }

        Test-Path -LiteralPath $perfil | Should-BeFalse
    }

    It 'mantém um perfil sem a linha como está' {
        Set-Content -LiteralPath $perfil -Value 'Set-Alias ll Get-ChildItem'
        $antes = [IO.File]::ReadAllText($perfil)

        InModuleScope WinPlaybook -Parameters @{ Perfil = $perfil } { Remove-AutocompleteDoPerfil -Perfil $Perfil }

        [IO.File]::ReadAllText($perfil) | Should-Be $antes
    }
}
