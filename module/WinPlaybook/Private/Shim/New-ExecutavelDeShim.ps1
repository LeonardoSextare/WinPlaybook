function New-ExecutavelDeShim {
    <#
    .SYNOPSIS
    Compila o executável que os shims .exe copiam, a partir do Shim.cs do módulo.

    .DESCRIPTION
    O executável lê o <nome>.shim que fica ao lado dele, com o programa (path) e os
    argumentos dele (args), e executa esse programa com a mesma entrada, as mesmas saídas e
    o mesmo console. Os argumentos que o executável recebe vão depois dos args, cada um como
    um x seguido do texto em UTF-8 codificado em Base64. Assim nenhum argumento chega ao
    PowerShell num formato que o -File interprete. O executável sai com o código de saída do
    programa.

    .PARAMETER Caminho
    O caminho do executável a criar. A pasta dele é criada quando não existe.

    .EXAMPLE
    New-ExecutavelDeShim -Caminho 'C:\Temp\shim.exe'

    .LINK
    https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-options/output
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Caminho
    )

    $caminhoDoCompilador = Get-CaminhoDoCompiladorCSharp
    $compiladorExiste = Test-Path -LiteralPath $caminhoDoCompilador
    if (-not $compiladorExiste) {
        throw (Get-Mensagem -Nome 'CompiladorNaoEncontrado' -Valores $caminhoDoCompilador)
    }

    $null = New-Item -ItemType Directory -Path (Split-Path -Path $Caminho -Parent) -Force
    $caminhoDoCodigo = Join-Path -Path $ExecutionContext.SessionState.Module.ModuleBase -ChildPath 'Shim.cs'

    $ErrorActionPreference = 'Continue'
    $saida = @(& $caminhoDoCompilador /nologo /target:exe /optimize+ "/out:$Caminho" $caminhoDoCodigo 2>&1 | ForEach-Object { "$_" })
    $compilou = $LASTEXITCODE -eq 0
    if (-not $compilou) {
        throw (Get-Mensagem -Nome 'ShimNaoCompilado' -Valores (($saida -join ' ').Trim()))
    }
}
