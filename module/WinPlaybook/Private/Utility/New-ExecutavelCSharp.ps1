function New-ExecutavelCSharp {
    <#
    .SYNOPSIS
    Compila um programa de console em C# da pasta do módulo, como o Shim.cs, com o compilador do .NET Framework.

    .PARAMETER Codigo
    O nome do arquivo de código na pasta do módulo, como Shim.cs.

    .PARAMETER Caminho
    O caminho do executável a criar. A pasta dele é criada quando não existe.

    .EXAMPLE
    New-ExecutavelCSharp -Codigo 'Shim.cs' -Caminho 'C:\Temp\shim.exe'

    .LINK
    https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-options/output
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Codigo,
        [Parameter(Mandatory)] [string] $Caminho
    )

    $caminhoDoCompilador = Get-CaminhoDoCompiladorCSharp
    $compiladorExiste = Test-Path -LiteralPath $caminhoDoCompilador
    if (-not $compiladorExiste) {
        throw (Get-Mensagem -Nome 'CompiladorNaoEncontrado' -Valores $caminhoDoCompilador)
    }

    $null = New-Item -ItemType Directory -Path (Split-Path -Path $Caminho -Parent) -Force
    $caminhoDoCodigo = Join-Path -Path $ExecutionContext.SessionState.Module.ModuleBase -ChildPath $Codigo

    $ErrorActionPreference = 'Continue'
    $saida = @(& $caminhoDoCompilador /nologo /target:exe /optimize+ "/out:$Caminho" $caminhoDoCodigo 2>&1 | ForEach-Object { "$_" })
    $compilou = $LASTEXITCODE -eq 0
    if (-not $compilou) {
        throw (Get-Mensagem -Nome 'ExecutavelNaoCompilado' -Valores $Codigo, (($saida -join ' ').Trim()))
    }
}
