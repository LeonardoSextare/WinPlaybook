function New-ExecutavelDeShimDeTeste {
    <#
    .SYNOPSIS
    Compila o executável dos shims com o New-ExecutavelDeShim do módulo e devolve o caminho dele.

    .DESCRIPTION
    O módulo WinPlaybook precisa estar importado.

    .PARAMETER Pasta
    A pasta onde o executável é criado.

    .EXAMPLE
    $caminhoDoExecutavel = New-ExecutavelDeShimDeTeste -Pasta (Join-Path $TestDrive 'executavel')
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Pasta
    )

    $caminhoDoExecutavel = Join-Path -Path $Pasta -ChildPath 'shim.exe'
    InModuleScope WinPlaybook -Parameters @{ Caminho = $caminhoDoExecutavel } { New-ExecutavelDeShim -Caminho $Caminho }

    return $caminhoDoExecutavel
}

function New-ModuloFalso {
    <#
    .SYNOPSIS
    Cria um módulo WinPlaybook falso, para os shims rodarem sem o WSL, e devolve a pasta dele.

    .DESCRIPTION
    O Invoke-WinPlaybook falso responde conforme o comando: mostra-argumentos escreve cada
    argumento entre colchetes, sai-com sai com o código do primeiro argumento, e le-a-entrada
    escreve o que chegou pela entrada padrão. A saída é em UTF-8.

    .PARAMETER Pasta
    A pasta onde a pasta WinPlaybook do módulo falso é criada.

    .EXAMPLE
    $pastaDoModuloFalso = New-ModuloFalso -Pasta (Join-Path $TestDrive 'modulo-falso')
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Pasta
    )

    $pastaDoModulo = Join-Path -Path $Pasta -ChildPath 'WinPlaybook'
    $null = New-Item -ItemType Directory -Path $pastaDoModulo -Force
    Set-Content -LiteralPath (Join-Path -Path $pastaDoModulo -ChildPath 'WinPlaybook.psm1') -Encoding UTF8 -Value @'
function Invoke-WinPlaybook {
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
    $global:LASTEXITCODE = 0
    $argumentos = @($args | Select-Object -Skip 1)
    switch ($args[0]) {
        'mostra-argumentos' { $argumentos | ForEach-Object { "[$_]" } }
        'sai-com' { $global:LASTEXITCODE = [int] $argumentos[0] }
        'le-a-entrada' { "entrada=[$([Console]::In.ReadToEnd().Trim())]" }
    }
}
'@

    return $pastaDoModulo
}
