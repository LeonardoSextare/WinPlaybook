function ConvertTo-LegacyNativeArgument {
    <#
    .SYNOPSIS
    Escapes arguments for the legacy way PowerShell passes arguments to programs.

    .DESCRIPTION
    Before PowerShell 7.3, PowerShell joins the arguments into a command line without
    escaping quotes, so a program such as docker receives {"a": 1} as {a: 1}. The rules
    are the ones Windows programs use to split a command line into arguments.

    .EXAMPLE
    ConvertTo-LegacyNativeArgument -Argument '-e', '{"a": 1}'

    Returns -e and {\"a\": 1}.

    .LINK
    https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [AllowEmptyString()] [string[]] $Argument
    )

    foreach ($value in $Argument) {
        $isEmpty = $value -eq ''
        if ($isEmpty) {
            Write-Output '""'
            continue
        }

        $escapedValue = $value -replace '(\\*)"', '$1$1\"'

        $hasWhitespace = $escapedValue -match '\s'
        if ($hasWhitespace) {
            $escapedValue = $escapedValue -replace '(\\+)$', '$1$1'
        }

        Write-Output $escapedValue
    }
}
