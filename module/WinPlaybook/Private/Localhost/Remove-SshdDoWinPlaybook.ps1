function Remove-SshdDoWinPlaybook {
    <#
    .SYNOPSIS
    Para e apaga o serviço SSH do WinPlaybook e a pasta da configuração dele.

    .DESCRIPTION
    Precisa de administrador. Sem o serviço ou a pasta, nada muda. A pasta WinPlaybook de
    %ProgramData% é apagada só se ficar vazia.

    .EXAMPLE
    Remove-SshdDoWinPlaybook
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $servico = Get-Service -Name 'WinPlaybookSshd' -ErrorAction SilentlyContinue
    if ($servico) {
        Stop-Service -Name 'WinPlaybookSshd' -Force -ErrorAction SilentlyContinue
        Get-CimInstance -ClassName Win32_Service -Filter "Name = 'WinPlaybookSshd'" | Invoke-CimMethod -MethodName Delete | Out-Null
    }

    $pasta = Get-PastaDoSshdDoWinPlaybook
    Remove-Item -LiteralPath $pasta -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Get-PastaDoOpenSshDoWinPlaybook) -Recurse -Force -ErrorAction SilentlyContinue
    Remove-PastaVazia -Pasta (Split-Path -Path $pasta -Parent)
}
