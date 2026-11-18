function Invoke-InstalacaoDaVersaoNova {
    <#
    .SYNOPSIS
    Roda o Install-WinPlaybook da versão do módulo mais nova instalada, num PowerShell novo da mesma edição.

    .DESCRIPTION
    O PowerShell atual continua com a versão antiga carregada, por isso a instalação roda
    num processo novo, que carrega a versão mais nova. A instalação mantém as escolhas
    salvas, como a versão do Ansible e os pacotes Python. Falha quando a instalação falha.

    .EXAMPLE
    Invoke-InstalacaoDaVersaoNova
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $powershell = (Get-Process -Id $PID).Path
    & $powershell -NoProfile -Command 'Import-Module WinPlaybook -Force -ErrorAction Stop; $null = Install-WinPlaybook -ErrorAction Stop'
    $instalou = $LASTEXITCODE -eq 0
    if (-not $instalou) {
        throw (Get-Mensagem -Nome 'InstalacaoDaVersaoNovaFalhou' -Valores $LASTEXITCODE)
    }
}
