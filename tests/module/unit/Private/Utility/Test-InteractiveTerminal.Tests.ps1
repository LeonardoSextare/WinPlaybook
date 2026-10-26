BeforeAll {
    $manifest = Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1'
    $powershell = (Get-Process -Id $PID).Path
    Import-Module $manifest -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Test-InteractiveTerminal' {
    It 'returns a boolean' {
        $result = InModuleScope WinPlaybook { Test-InteractiveTerminal }

        $result | Should-HaveType ([bool])
    }

    Context 'when the output is redirected' {
        It 'returns false' {
            $script = "Import-Module '$manifest'; & (Get-Module WinPlaybook) { Test-InteractiveTerminal }"

            $result = & $powershell -NoProfile -NonInteractive -Command $script

            $result | Should-Be 'False'
        }
    }
}
