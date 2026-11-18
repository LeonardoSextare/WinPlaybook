function Get-CaminhoDoLog {
    <#
    .SYNOPSIS
    Devolve o arquivo de log do dia, na pasta logs da configuração do WinPlaybook.

    .DESCRIPTION
    Há um arquivo por dia, winplaybook-<ano>-<mês>-<dia>.log, em
    %LOCALAPPDATA%\WinPlaybook\logs. O arquivo e a pasta podem não existir.

    .EXAMPLE
    Get-CaminhoDoLog

    Devolve C:\Users\<usuário>\AppData\Local\WinPlaybook\logs\winplaybook-2026-11-18.log.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $pastaDosLogs = Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'logs'
    return Join-Path -Path $pastaDosLogs -ChildPath "winplaybook-$((Get-Date).ToString('yyyy-MM-dd')).log"
}
