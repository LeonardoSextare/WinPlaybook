@{
    RootModule           = 'WinPlaybook.psm1'
    ModuleVersion        = '0.0.0'
    GUID                 = '1c1dda68-daf7-4f79-bf94-608727b28b2f'
    Author               = 'Leonardo Sextare'
    Copyright            = '(c) Leonardo Sextare. MIT License.'
    Description          = 'Use o Ansible no Windows como se ele estivesse instalado localmente.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    FunctionsToExport    = @(
        'Disable-WinPlaybookVSCodeExtension'
        'Enable-WinPlaybookVSCodeExtension'
        'Install-WinPlaybook'
        'Invoke-WinPlaybook'
        'Uninstall-WinPlaybook'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags       = @('Ansible', 'WSL', 'Windows', 'Automation')
            ProjectUri = 'https://github.com/LeonardoSextare/WinPlaybook'
            LicenseUri = 'https://github.com/LeonardoSextare/WinPlaybook/blob/main/LICENSE'
        }
    }
}
