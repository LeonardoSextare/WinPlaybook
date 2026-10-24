BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ProjectRoot' {
    Context 'when the folder is inside a git repository' {
        It 'returns the repository root when called from the root' {
            $root = Join-Path $TestDrive 'from-root'
            New-Item -ItemType Directory -Path (Join-Path $root '.git') -Force | Out-Null

            $result = InModuleScope WinPlaybook -Parameters @{ Path = $root } {
                Get-ProjectRoot -Path $Path
            }

            $result | Should-Be $root
        }

        It 'returns the repository root when called from a subfolder' {
            $root = Join-Path $TestDrive 'from-subfolder'
            New-Item -ItemType Directory -Path (Join-Path $root '.git') -Force | Out-Null
            $subfolder = New-Item -ItemType Directory -Path (Join-Path $root 'playbooks/roles') -Force

            $result = InModuleScope WinPlaybook -Parameters @{ Path = $subfolder.FullName } {
                Get-ProjectRoot -Path $Path
            }

            $result | Should-Be $root
        }

        It 'returns the repository root when .git is a file' {
            $root = Join-Path $TestDrive 'git-file'
            New-Item -ItemType File -Path (Join-Path $root '.git') -Force | Out-Null
            $subfolder = New-Item -ItemType Directory -Path (Join-Path $root 'playbooks') -Force

            $result = InModuleScope WinPlaybook -Parameters @{ Path = $subfolder.FullName } {
                Get-ProjectRoot -Path $Path
            }

            $result | Should-Be $root
        }

        It 'returns the closest repository when repositories are nested' {
            $outer = Join-Path $TestDrive 'nested'
            $inner = Join-Path $outer 'submodule'
            New-Item -ItemType Directory -Path (Join-Path $outer '.git') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $inner '.git') -Force | Out-Null
            $subfolder = New-Item -ItemType Directory -Path (Join-Path $inner 'playbooks') -Force

            $result = InModuleScope WinPlaybook -Parameters @{ Path = $subfolder.FullName } {
                Get-ProjectRoot -Path $Path
            }

            $result | Should-Be $inner
        }

        It 'returns the repository root when the path has brackets' {
            $root = Join-Path $TestDrive 'project[1]'
            New-Item -ItemType Directory -Path (Join-Path $root '.git') -Force | Out-Null
            $subfolder = New-Item -ItemType Directory -Path (Join-Path $root 'playbooks') -Force

            $result = InModuleScope WinPlaybook -Parameters @{ Path = $subfolder.FullName } {
                Get-ProjectRoot -Path $Path
            }

            $result | Should-Be $root
        }
    }

    Context 'when the folder is outside a git repository' {
        It 'returns the folder itself' {
            $folder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'no-repository/playbooks') -Force

            $result = InModuleScope WinPlaybook -Parameters @{ Path = $folder.FullName } {
                Get-ProjectRoot -Path $Path
            }

            $result | Should-Be $folder.FullName
        }
    }
}
