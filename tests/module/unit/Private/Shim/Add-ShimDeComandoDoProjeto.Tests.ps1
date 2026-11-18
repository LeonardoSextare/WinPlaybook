BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Add-ShimDeComandoDoProjeto' {
    BeforeEach {
        $pastaDosShims = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $pastaDosShims
        [IO.File]::WriteAllText((Join-Path $pastaDosShims 'ansible.exe'), 'executavel do shim')
        $caminhoDaLista = Join-Path $TestDrive "lista-$([guid]::NewGuid().ToString('N')).txt"
        $parametros = @{ CaminhoDaLista = $caminhoDaLista; PastaDosShims = $pastaDosShims }
    }

    Context 'quando o supervisor gravou a lista de comandos do projeto' {
        BeforeEach {
            [IO.File]::WriteAllText($caminhoDaLista, "ansible`nmolecule`nyamllint`n`n../fora`n")
            InModuleScope WinPlaybook -Parameters $parametros { Add-ShimDeComandoDoProjeto -CaminhoDaLista $CaminhoDaLista -PastaDosShims $PastaDosShims -CaminhoDoPowerShell 'C:\PowerShell\pwsh.exe' }
        }

        It 'cria o shim do <_>, que ainda não tinha um' -ForEach @('molecule', 'yamllint') {
            Get-Content -LiteralPath (Join-Path $pastaDosShims "$_.exe") -Raw | Should-Be 'executavel do shim'
            Test-Path -LiteralPath (Join-Path $pastaDosShims "$_.ps1") | Should-BeTrue
        }

        It 'não cria shim para um nome que não é de comando' {
            @(Get-ChildItem -LiteralPath (Split-Path -Parent $pastaDosShims) -Filter 'fora*') | Should-BeCollection @()
        }

        It 'apaga a lista' {
            Test-Path -LiteralPath $caminhoDaLista | Should-BeFalse
        }
    }

    It 'não faz nada sem a lista' {
        InModuleScope WinPlaybook -Parameters $parametros { Add-ShimDeComandoDoProjeto -CaminhoDaLista $CaminhoDaLista -PastaDosShims $PastaDosShims -CaminhoDoPowerShell 'C:\PowerShell\pwsh.exe' }

        @(Get-ChildItem -LiteralPath $pastaDosShims | ForEach-Object { $_.Name }) | Should-BeCollection @('ansible.exe')
    }
}
