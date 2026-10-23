BeforeDiscovery {
    $ansibleCommands = @(
        'ansible'
        'ansible-config'
        'ansible-console'
        'ansible-creator'
        'ansible-doc'
        'ansible-galaxy'
        'ansible-inventory'
        'ansible-lint'
        'ansible-playbook'
        'ansible-pull'
        'ansible-test'
        'ansible-vault'
    )
    $externalTools = @('ssh', 'git', 'less')
}

BeforeAll {
    . (Join-Path $PSScriptRoot '../helpers/Docker.ps1')
    $container = Start-TestContainer (Build-TestImage)
}

AfterAll {
    Stop-TestContainer $container
}

Describe 'Container contents' {
    It 'provides the <_> command' -ForEach $ansibleCommands {
        $result = Invoke-InContainer $container -Command 'sh', '-c', "command -v $_"

        $result.ExitCode | Should-Be 0
    }

    It 'provides <_> for Ansible to call' -ForEach $externalTools {
        $result = Invoke-InContainer $container -Command 'sh', '-c', "command -v $_"

        $result.ExitCode | Should-Be 0
    }

    It 'has the configured editor installed' {
        $result = Invoke-InContainer $container -Command 'sh', '-c', 'command -v "$EDITOR"'

        $result.ExitCode | Should-Be 0
    }
}
