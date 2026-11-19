function Write-ProgressoDoAdministrador {
    <#
    .SYNOPSIS
    Conta, de dentro do PowerShell de administrador, qual parte do comando está rodando, para a janela principal mostrar.

    .DESCRIPTION
    O Invoke-ComoAdministrador aponta a variável WINPLAYBOOK_PROGRESS_FILE para um arquivo
    temporário e, enquanto espera, mostra a última linha dele na etapa em andamento. Fora do
    PowerShell de administrador, sem a variável, a função troca direto o texto da etapa em
    andamento, se houver.

    .PARAMETER Texto
    A parte que está rodando, como "Instalando o OpenSSH Server".

    .EXAMPLE
    Write-ProgressoDoAdministrador -Texto 'Instalando o OpenSSH Server'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Texto
    )

    $arquivo = $env:WINPLAYBOOK_PROGRESS_FILE
    $temArquivo = [bool] $arquivo
    if (-not $temArquivo) {
        Set-TextoDaEtapa -Texto $Texto
        return
    }

    [IO.File]::AppendAllText($arquivo, $Texto + [Environment]::NewLine)
}
