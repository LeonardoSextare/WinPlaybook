BeforeAll {
    . (Join-Path $PSScriptRoot '../../shared/helpers/Process.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Shim.ps1')
    $powershellPath = (Get-Process -Id $PID).Path
}

Describe 'Shim' {
    Context 'when the target prints its arguments' {
        BeforeAll {
            $scriptPath = Join-Path $TestDrive 'print-args.ps1'
            Set-Content -LiteralPath $scriptPath -Value '$args | ForEach-Object { "[$_]" }'
            $shimPath = New-TestShim -Folder $TestDrive -Name 'print-args' -TargetPath $powershellPath `
                -TargetArguments "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        }

        It 'passes <Description> unchanged' -ForEach @(
            @{ Description = 'JSON with quotes and spaces'; Arguments = '"{\"x\": \"y z\"}"'; Expected = '[{"x": "y z"}]' }
            @{ Description = 'a percent sign'; Arguments = 'discount=50%PATH%'; Expected = '[discount=50%PATH%]' }
            @{ Description = 'a caret'; Arguments = 'a^b'; Expected = '[a^b]' }
            @{ Description = 'an ampersand'; Arguments = 'a&b'; Expected = '[a&b]' }
            @{ Description = 'a path with spaces'; Arguments = '"folder with spaces\site.yml"'; Expected = '[folder with spaces\site.yml]' }
        ) {
            $result = Invoke-CommandLine -FilePath $shimPath -ArgumentList $Arguments

            $result.Output | Should-Be $Expected
        }

        It 'passes several arguments in order' {
            $result = Invoke-CommandLine -FilePath $shimPath -ArgumentList '-i inventory.yml site.yml'

            $result.Output -split '\r?\n' | Should-BeCollection @('[-i]', '[inventory.yml]', '[site.yml]')
        }
    }

    Context 'when the target exits with a code' {
        BeforeAll {
            $shimPath = New-TestShim -Folder $TestDrive -Name 'exit-with' -TargetPath $powershellPath `
                -TargetArguments '-NoProfile -Command exit 7'
        }

        It 'propagates the exit code of the target' {
            $result = Invoke-CommandLine -FilePath $shimPath

            $result.ExitCode | Should-Be 7
        }
    }
}
