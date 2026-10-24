function Test-InteractiveTerminal {
    <#
    .SYNOPSIS
    Tells whether PowerShell is attached to a terminal, with no input or output redirected.

    .EXAMPLE
    Test-InteractiveTerminal

    Returns False when PowerShell runs with its output piped to a file or another program.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected
}
