@{
    RootModule           = 'WinPlaybook.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = '1c1dda68-daf7-4f79-bf94-608727b28b2f'
    Author               = 'Leonardo Sextare'
    Copyright            = '(c) Leonardo Sextare. MIT License.'
    Description          = 'Use Ansible on Windows as if it were installed locally.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    FunctionsToExport    = @(
        'Install-WinPlaybookShim'
        'Invoke-WinPlaybook'
        'Uninstall-WinPlaybookShim'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
}
