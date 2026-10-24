function Remove-UserPathEntry {
    <#
    .SYNOPSIS
    Removes a folder from the user Path and from the Path of the current session.

    .DESCRIPTION
    The other entries of the user Path are kept as they are, including the ones that
    use environment variables, such as %USERPROFILE%\bin.

    .EXAMPLE
    Remove-UserPathEntry -Folder 'C:\shims'
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
        $remainingEntries = @($entries | Where-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') -ne $folderEntry })
        $paths[$scope] = @{
            HasFolder = $remainingEntries.Count -lt $entries.Count
            NewValue  = $remainingEntries -join ';'
        }
    }

    if ($paths.User.HasFolder) {
        $isOnlyEntry = -not $paths.User.NewValue
        if ($isOnlyEntry) {
            Remove-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $VariableName
        }
        else {
            New-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $VariableName -Value $paths.User.NewValue -PropertyType ExpandString -Force | Out-Null
        }
        Send-EnvironmentChange
    }

    if ($paths.Session.HasFolder) {
        $isOnlyEntry = -not $paths.Session.NewValue
        if ($isOnlyEntry) {
            Remove-Item -LiteralPath "Env:$VariableName"
        }
        else {
            Set-Item -LiteralPath "Env:$VariableName" -Value $paths.Session.NewValue
        }
    }
}
