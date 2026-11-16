function Get-CaminhoDoCompiladorCSharp {
    <#
    .SYNOPSIS
    Devolve o caminho do compilador de C# do .NET Framework 4, que vem no Windows.

    .EXAMPLE
    Get-CaminhoDoCompiladorCSharp

    Devolve C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe.

    .LINK
    https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-options/
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
}
