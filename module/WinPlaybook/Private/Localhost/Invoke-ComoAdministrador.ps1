function Invoke-ComoAdministrador {
    <#
    .SYNOPSIS
    Roda um comando do WinPlaybook num PowerShell elevado, que o Windows pede para o usuário aprovar, e espera ele terminar.

    .DESCRIPTION
    O PowerShell elevado é da mesma edição do atual e carrega o módulo pela mesma pasta.
    Falha quando o usuário recusa a elevação ou quando o comando falha.

    .PARAMETER Comando
    O comando, como 'Enable-WinPlaybookLocalhost -Confirm:$false'.

    .EXAMPLE
    Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost -Confirm:$false'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Comando
    )

    $script = "`$ErrorActionPreference = 'Stop'; Import-Module '$((Get-PastaDoModulo).Replace("'", "''"))'; $Comando"
    $comandoCodificado = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
    try {
        $processo = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList '-NoProfile', '-EncodedCommand', $comandoCodificado -Verb RunAs -Wait -PassThru
    }
    catch {
        throw (Get-Mensagem -Nome 'ElevacaoRecusada' -Valores $_.Exception.Message)
    }

    $terminouBem = $processo.ExitCode -eq 0
    if (-not $terminouBem) {
        throw (Get-Mensagem -Nome 'ComandoComoAdministradorFalhou' -Valores $Comando, $processo.ExitCode)
    }
}
