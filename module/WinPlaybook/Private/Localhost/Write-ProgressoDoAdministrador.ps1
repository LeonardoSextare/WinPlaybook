function Write-ProgressoDoAdministrador {
    <#
    .SYNOPSIS
    Conta que uma etapa do plano começou ou terminou, mesmo de dentro do PowerShell de administrador.

    .DESCRIPTION
    No PowerShell de administrador, o Invoke-ComoAdministrador aponta a variável
    WINPLAYBOOK_PROGRESS_FILE para um arquivo temporário, e a função acrescenta a ele uma
    linha, como "inicio localhost.chave", que a janela principal aplica ao plano dela. Fora
    dele, sem a variável, a função atualiza direto o plano em andamento, se houver.

    .PARAMETER Id
    A etapa do plano, como localhost.chave.

    .PARAMETER Fim
    A etapa terminou. Sem ele e sem -Remocao, ela começou.

    .PARAMETER Remocao
    A etapa terminou e removeu algo.

    .EXAMPLE
    Write-ProgressoDoAdministrador -Id 'localhost.chave'

    .EXAMPLE
    Write-ProgressoDoAdministrador -Id 'localhost.chave' -Fim
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Id,
        [switch] $Fim,
        [switch] $Remocao
    )

    $evento = 'inicio'
    if ($Fim) {
        $evento = 'fim'
    }
    if ($Remocao) {
        $evento = 'remocao'
    }

    $arquivo = $env:WINPLAYBOOK_PROGRESS_FILE
    $temArquivo = [bool] $arquivo
    if ($temArquivo) {
        [IO.File]::AppendAllText($arquivo, "$evento $Id" + [Environment]::NewLine)
        return
    }

    $plano = Get-Variable -Name 'Plano' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $temPlano = $null -ne $plano
    if (-not $temPlano) {
        return
    }
    Set-EventoDoPlano -Plano $plano -Evento $evento -Id $Id
}
