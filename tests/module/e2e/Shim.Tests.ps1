BeforeAll {
    . (Join-Path $PSScriptRoot '../../shared/helpers/Process.ps1')
    . (Join-Path $PSScriptRoot '../../shared/helpers/Wsl.ps1')

    $wslDistributionName = Initialize-TestWslDistribution

    $originalLocalAppData = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $TestDrive 'local'

    $originalModulePath = $env:PSModulePath
    $moduleFolder = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../module'))
    $env:PSModulePath = $moduleFolder + [IO.Path]::PathSeparator + $env:PSModulePath
    Import-Module (Join-Path $moduleFolder 'WinPlaybook/WinPlaybook.psd1') -Force

    $windowsToolFolder = Join-Path $TestDrive 'windows-tools'
    New-Item -ItemType File -Path (Join-Path $windowsToolFolder 'ansible-windows.exe') -Force | Out-Null
    $originalPath = $env:Path
    $env:Path = $windowsToolFolder + [IO.Path]::PathSeparator + $env:Path

    $shimFolder = Join-Path $TestDrive 'shims'
    New-Item -ItemType Directory -Path $shimFolder | Out-Null
    $shimParameters = @{ Folder = $shimFolder; PowerShellPath = (Get-Process -Id $PID).Path; Distribution = $wslDistributionName }
    InModuleScope WinPlaybook -Parameters $shimParameters {
        $mountRoot = Get-WslMountRoot -Distribution $Distribution
        Save-Setting -Settings @{ WslDistribution = $Distribution; WslMountRoot = $mountRoot }
        foreach ($command in Get-AnsibleCommand -Distribution $Distribution -MountRoot $mountRoot) {
            New-CommandShim -Name $command -Folder $Folder -PowerShellPath $PowerShellPath
        }
    }
    $env:Path = $originalPath

    $project = Join-Path $TestDrive 'project'
    Copy-Item (Join-Path $PSScriptRoot '../../shared/data/projects/hello') $project -Recurse
    Push-Location $project
}

AfterAll {
    Pop-Location
    Remove-Module WinPlaybook
    $env:PSModulePath = $originalModulePath
    $env:LOCALAPPDATA = $originalLocalAppData
}

Describe 'Shim' {
    Context 'when called from PowerShell' {
        It 'runs the playbook' {
            $output = & (Join-Path $shimFolder 'ansible-playbook.ps1') site.yml 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*hello from WinPlaybook*'
        }

        It 'passes JSON extra variables unchanged' {
            $output = & (Join-Path $shimFolder 'ansible.ps1') localhost -m ansible.builtin.debug -a 'msg={{ greeting }}' -e '{"greeting": "hello world"}' 2>&1 | Out-String

            $LASTEXITCODE | Should-Be 0 -Because $output
            $output | Should-BeLikeString '*"msg": "hello world"*'
        }
    }

    Context 'when called by another program' {
        It 'runs the playbook' {
            $result = Invoke-CommandLine -FilePath (Join-Path $shimFolder 'ansible-playbook.exe') -ArgumentList 'site.yml'

            $result.ExitCode | Should-Be 0 -Because $result.Output
            $result.Output | Should-BeLikeString '*hello from WinPlaybook*'
        }

        It 'passes JSON extra variables unchanged' {
            $arguments = 'localhost -m ansible.builtin.debug -a "msg={{ greeting }}" -e "{\"greeting\": \"hello world\"}"'

            $result = Invoke-CommandLine -FilePath (Join-Path $shimFolder 'ansible.exe') -ArgumentList $arguments

            $result.ExitCode | Should-Be 0 -Because $result.Output
            $result.Output | Should-BeLikeString '*"msg": "hello world"*'
        }

        It 'propagates the exit code of the command' {
            $result = Invoke-CommandLine -FilePath (Join-Path $shimFolder 'ansible-playbook.exe') -ArgumentList 'missing.yml'

            $result.ExitCode | Should-Be 1 -Because $result.Output
        }
    }

    Context 'when the Windows Path has an ansible program' {
        It 'creates no shim for it' {
            $shimNames = (Get-ChildItem -LiteralPath $shimFolder -Filter '*.ps1').BaseName

            $shimNames | Should-NotContainCollection 'ansible-windows.exe'
        }
    }
}
