function Save-Configuracao {
    <#
    .SYNOPSIS
    Grava a configuração do WinPlaybook em JSON, na pasta de configuração.

    .DESCRIPTION
    Substitui a configuração salva antes e cria a pasta de configuração quando ela ainda
    não existe.

    .PARAMETER Configuracao
    As chaves e os valores da configuração, no formato que Get-Configuracao devolve.

    .EXAMPLE
    Save-Configuracao -Configuracao @{ ShimFolder = 'C:\Tools\WinPlaybook\bin'; ShimPowerShellPath = 'C:\Program Files\PowerShell\7\pwsh.exe' }
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Configuracao
    )

    $pastaDeConfiguracao = Get-PastaDeConfiguracao
    $null = New-Item -ItemType Directory -Path $pastaDeConfiguracao -Force
    $Configuracao | ConvertTo-Json | Set-Content -LiteralPath (Join-Path -Path $pastaDeConfiguracao -ChildPath 'settings.json') -Encoding UTF8
}
