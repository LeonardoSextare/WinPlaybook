function Add-UserPathEntry {
    <#
    .SYNOPSIS
    Puts a folder at the start of the user Path and of the Path of the current session.

    .DESCRIPTION
    The user Path is read and written in the registry as an expandable string, so
    entries such as %USERPROFILE%\bin keep working. The session Path makes the folder
    available right away in the current terminal.

    .EXAMPLE
    Add-UserPathEntry -Folder 'C:\shims'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Folder,
        [string] $VariableName = 'Path'
    )

    $folderEntry = $Folder.TrimEnd('\')

    $currentValues = @{
        User    = (Get-Item -LiteralPath 'HKCU:\Environment').GetValue($VariableName, '', 'DoNotExpandEnvironmentNames')
        Session = [Environment]::GetEnvironmentVariable($VariableName, 'Process')
    }

    $paths = @{}
    foreach ($scope in $currentValues.Keys) {
        $entries = @("$($currentValues[$scope])".Split(';') | Where-Object { $_ })
        $normalizedEntries = $entries | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }
        $paths[$scope] = @{
            HasFolder = $normalizedEntries -contains $folderEntry
            NewValue  = (@($Folder) + $entries) -join ';'
        }
    }

    if (-not $paths.User.HasFolder) {
        New-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $VariableName -Value $paths.User.NewValue -PropertyType ExpandString -Force | Out-Null
        Send-EnvironmentChange
    }

    if (-not $paths.Session.HasFolder) {
        Set-Item -LiteralPath "Env:$VariableName" -Value $paths.Session.NewValue
    }
}
