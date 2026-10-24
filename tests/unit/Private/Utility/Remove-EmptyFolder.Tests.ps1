BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-EmptyFolder' {
    It 'removes an empty folder' {
        $folder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'empty')

        InModuleScope WinPlaybook -Parameters @{ Folder = $folder.FullName } { Remove-EmptyFolder -Folder $Folder }

        Test-Path -LiteralPath $folder.FullName | Should-BeFalse
    }

    It 'keeps a folder with files' {
        $folder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'with-files')
        Set-Content -LiteralPath (Join-Path $folder.FullName 'file.txt') -Value 'kept'

        InModuleScope WinPlaybook -Parameters @{ Folder = $folder.FullName } { Remove-EmptyFolder -Folder $Folder }

        Test-Path -LiteralPath $folder.FullName | Should-BeTrue
    }

    It 'ignores a folder that does not exist' {
        $folder = Join-Path $TestDrive 'missing'

        $result = InModuleScope WinPlaybook -Parameters @{ Folder = $folder } { Remove-EmptyFolder -Folder $Folder }

        $result | Should-BeNull
    }
}
