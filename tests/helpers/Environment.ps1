function New-TestVariableName {
    "WINPLAYBOOK_TEST_$([guid]::NewGuid().ToString('N'))"
}

function Set-TestUserVariable([string] $Name, [string] $Value) {
    New-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $Name -Value $Value -PropertyType ExpandString -Force | Out-Null
}

function Get-TestUserVariable([string] $Name) {
    $environmentKey = Get-Item -LiteralPath 'HKCU:\Environment'
    $exists = $environmentKey.GetValueNames() -contains $Name
    if (-not $exists) {
        return $null
    }

    [pscustomobject]@{
        Value = $environmentKey.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
        Kind  = $environmentKey.GetValueKind($Name).ToString()
    }
}

function Remove-TestVariable([string] $Name) {
    Remove-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $Name -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
}

function Clear-TestVariable {
    $testVariableNames = (Get-Item -LiteralPath 'HKCU:\Environment').GetValueNames() |
        Where-Object { $_.StartsWith('WINPLAYBOOK_TEST_') }
    foreach ($name in $testVariableNames) {
        Remove-TestVariable -Name $name
    }
}
