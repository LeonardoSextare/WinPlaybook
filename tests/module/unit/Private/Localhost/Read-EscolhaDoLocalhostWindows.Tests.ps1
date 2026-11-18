BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Read-EscolhaDoLocalhostWindows' {
    It 'devolve <Esperado> quando o usuário escolhe a opção <Escolha>' -ForEach @(
        @{ Escolha = 0; Esperado = $true }
        @{ Escolha = 1; Esperado = $false }
    ) {
        $resposta = InModuleScope WinPlaybook -Parameters @{ Escolha = $Escolha } {
            $hostFalso = [pscustomobject]@{ UI = [pscustomobject]@{} }
            $hostFalso.UI | Add-Member -MemberType ScriptMethod -Name PromptForChoice -Value ([scriptblock]::Create("return $Escolha"))
            $Host = $hostFalso
            Read-EscolhaDoLocalhostWindows
        }

        $resposta | Should-Be $Esperado
    }
}
