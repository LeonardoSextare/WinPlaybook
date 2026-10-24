BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'New-CommandShim' {
    BeforeAll {
        $templatePath = Join-Path $TestDrive 'template.exe'
        Set-Content -LiteralPath $templatePath -Value 'template shim'
        Mock Get-ShimTemplatePath -ModuleName WinPlaybook { $templatePath }
    }

    Context 'when a shim is created' {
        BeforeAll {
            $shimFolder = Join-Path $TestDrive 'shims'
            New-Item -ItemType Directory -Path $shimFolder | Out-Null

            InModuleScope WinPlaybook -Parameters @{ Folder = $shimFolder } {
                New-CommandShim -Name 'ansible-playbook' -Folder $Folder -PowerShellPath 'C:\PowerShell\pwsh.exe'
            }
        }

        It 'writes a script that runs the command through the module' {
            $content = Get-Content -LiteralPath (Join-Path $shimFolder 'ansible-playbook.ps1')

            $content | Should-Be "WinPlaybook\Invoke-WinPlaybook 'ansible-playbook' @args"
        }

        It 'copies the packaged shim as the executable' {
            $content = Get-Content -LiteralPath (Join-Path $shimFolder 'ansible-playbook.exe')

            $content | Should-Be 'template shim'
        }

        It 'points the executable to the script through the chosen PowerShell' {
            $scriptPath = Join-Path $shimFolder 'ansible-playbook.ps1'

            $content = Get-Content -LiteralPath (Join-Path $shimFolder 'ansible-playbook.shim') -Encoding UTF8

            $content | Should-BeCollection @(
                'path = C:\PowerShell\pwsh.exe'
                "args = -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            )
        }
    }

    Context 'when the folder has non-ASCII characters' {
        BeforeAll {
            $folderName = "pasta-a$([char]0x00E7)$([char]0x00E3)o"
            $shimFolder = Join-Path $TestDrive $folderName
            New-Item -ItemType Directory -Path $shimFolder | Out-Null

            InModuleScope WinPlaybook -Parameters @{ Folder = $shimFolder } {
                New-CommandShim -Name 'ansible' -Folder $Folder -PowerShellPath 'C:\PowerShell\pwsh.exe'
            }
        }

        It 'writes the shim configuration in UTF-8' {
            $bytes = [IO.File]::ReadAllBytes((Join-Path $shimFolder 'ansible.shim'))

            [Text.Encoding]::UTF8.GetString($bytes) | Should-BeLikeString "*$folderName*"
        }
    }
}
