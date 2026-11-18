function Add-ShimDeComandoDoProjeto {
    <#
    .SYNOPSIS
    Cria os shims que faltam para os comandos do ambiente de um projeto, a partir da lista que o supervisor gravou, e apaga a lista.

    .DESCRIPTION
    O supervisor de Get-ScriptDoSupervisor grava, um por linha, os comandos do ambiente do
    projeto, como o molecule de um pyproject.toml. Cada comando que ainda não tem shim na
    pasta dos shims ganha um, como os que o Install-WinPlaybook cria, com o executável de um
    shim que já existe. Sem a lista, ou sem shims na pasta, nada muda.

    .PARAMETER CaminhoDaLista
    O arquivo com a lista de comandos.

    .PARAMETER PastaDosShims
    A pasta dos shims, como a ShimFolder da configuração.

    .PARAMETER CaminhoDoPowerShell
    O PowerShell que os shims .exe abrem, como o ShimPowerShellPath da configuração.

    .EXAMPLE
    Add-ShimDeComandoDoProjeto -CaminhoDaLista $caminhoDaLista -PastaDosShims $configuracao.ShimFolder -CaminhoDoPowerShell $configuracao.ShimPowerShellPath
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $CaminhoDaLista,
        [Parameter(Mandatory)] [string] $PastaDosShims,
        [Parameter(Mandatory)] [string] $CaminhoDoPowerShell
    )

    $temLista = Test-Path -LiteralPath $CaminhoDaLista -PathType Leaf
    if (-not $temLista) {
        return
    }

    try {
        $executavel = Get-ChildItem -LiteralPath $PastaDosShims -Filter '*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $executavel) {
            return
        }

        foreach ($comando in Get-Content -LiteralPath $CaminhoDaLista -Encoding UTF8) {
            $ehUmNomeDeComando = $comando -match '^[\w][\w.+-]*$'
            $jaTemShim = $ehUmNomeDeComando -and (Test-Path -LiteralPath (Join-Path -Path $PastaDosShims -ChildPath "$comando.exe") -PathType Leaf)
            if ($ehUmNomeDeComando -and -not $jaTemShim) {
                New-ShimDeComando -Nome $comando -Pasta $PastaDosShims -CaminhoDoPowerShell $CaminhoDoPowerShell -PastaDoModulo (Get-PastaDoModulo) -CaminhoDoExecutavel $executavel.FullName
            }
        }
    }
    finally {
        Remove-Item -LiteralPath $CaminhoDaLista -Force -ErrorAction SilentlyContinue
    }
}
