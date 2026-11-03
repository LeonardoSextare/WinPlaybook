function Invoke-Wsl([string[]] $Arguments) {
    $ErrorActionPreference = 'Continue'
    $output = & wsl @Arguments 2>&1 | ForEach-Object { "$_" }
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output -join [Environment]::NewLine
    }
}

function Initialize-TestWslDistribution {
    $name = $env:WINPLAYBOOK_TEST_WSL_DISTRIBUTION
    if (-not $name) {
        $name = 'WinPlaybookTest'
    }

    $originalUtf8 = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $installedNames = (Invoke-Wsl @('--list', '--quiet')).Output -split '\r?\n'
        $isInstalled = $installedNames -contains $name
        if (-not $isInstalled) {
            $result = Invoke-Wsl @('--install', 'Ubuntu', '--name', $name, '--no-launch')
            if ($result.ExitCode -ne 0) {
                throw "Failed to install the WSL distribution ${name}: $($result.Output)"
            }
        }

        $setupCommands = @(
            'command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh'
            'uv tool install ansible-core'
            'uv tool install ansible-lint'
        )
        foreach ($setupCommand in $setupCommands) {
            $result = Invoke-Wsl @('-d', $name, '-e', 'bash', '-lc', $setupCommand)
            if ($result.ExitCode -ne 0) {
                throw "Failed to run '$setupCommand' in the WSL distribution ${name}: $($result.Output)"
            }
        }
    }
    finally {
        $env:WSL_UTF8 = $originalUtf8
    }

    $name
}
