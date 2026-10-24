BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Docker.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Process.ps1')

    $originalImage = $env:WINPLAYBOOK_IMAGE
    $originalModulePath = $env:PSModulePath
    $env:WINPLAYBOOK_IMAGE = Build-TestImage
    $moduleFolder = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../module'))
    $env:PSModulePath = $moduleFolder + [IO.Path]::PathSeparator + $env:PSModulePath
    Import-Module (Join-Path $moduleFolder 'WinPlaybook/WinPlaybook.psd1') -Force

    $shimFolder = Join-Path $TestDrive 'shims'
    New-Item -ItemType Directory -Path $shimFolder | Out-Null
    InModuleScope WinPlaybook -Parameters @{ Folder = $shimFolder; PowerShellPath = (Get-Process -Id $PID).Path } {
        foreach ($command in Get-AnsibleCommand) {
            New-CommandShim -Name $command -Folder $Folder -PowerShellPath $PowerShellPath
        }
    }

    $project = Join-Path $TestDrive 'project'
    Copy-Item (Join-Path $PSScriptRoot '../data/projects/hello') $project -Recurse
    Push-Location $project
}

AfterAll {
    Pop-Location
    Remove-Module WinPlaybook
    $env:PSModulePath = $originalModulePath
    $env:WINPLAYBOOK_IMAGE = $originalImage
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
}
