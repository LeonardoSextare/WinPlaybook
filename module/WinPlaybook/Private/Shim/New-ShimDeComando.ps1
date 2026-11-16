function New-ShimDeComando {
    <#
    .SYNOPSIS
    Cria os arquivos que deixam um comando da distribuição WSL disponível no Windows.

    .DESCRIPTION
    O PowerShell executa o <comando>.ps1 no próprio processo, e o que chega pelo pipeline vai
    para o comando. Os outros programas executam o <comando>.exe, uma cópia do executável de
    New-ExecutavelDeShim, que lê o <comando>.shim e abre o PowerShell escolhido com o
    exe\<comando>.ps1. Esse script decodifica os argumentos que o executável codificou e não
    lê a entrada padrão, que chega ao comando sem passar pelo PowerShell.

    Os dois scripts carregam o módulo pela pasta dele, então funcionam nas duas edições do
    PowerShell, mesmo quando o módulo foi instalado só para uma delas.

    .PARAMETER Nome
    O nome do comando na distribuição, como ansible-playbook.

    .PARAMETER Pasta
    A pasta onde os arquivos são criados.

    .PARAMETER CaminhoDoPowerShell
    O PowerShell que o .exe abre.

    .PARAMETER PastaDoModulo
    A pasta que os scripts passam ao Import-Module, como a que Get-PastaDoModulo devolve.

    .PARAMETER CaminhoDoExecutavel
    O executável que New-ExecutavelDeShim compilou, copiado como o <comando>.exe.

    .EXAMPLE
    New-ShimDeComando -Nome 'ansible-playbook' -Pasta 'C:\shims' -CaminhoDoPowerShell 'C:\Program Files\PowerShell\7\pwsh.exe' -PastaDoModulo (Get-PastaDoModulo) -CaminhoDoExecutavel 'C:\Temp\shim.exe'

    Cria ansible-playbook.ps1, ansible-playbook.exe, ansible-playbook.shim e exe\ansible-playbook.ps1 em C:\shims.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $Pasta,
        [Parameter(Mandatory)] [string] $CaminhoDoPowerShell,
        [Parameter(Mandatory)] [string] $PastaDoModulo,
        [Parameter(Mandatory)] [string] $CaminhoDoExecutavel
    )

    $importacaoDoModulo = "Import-Module '$($PastaDoModulo.Replace("'", "''"))' -ErrorAction Stop"

    $caminhoDoScript = Join-Path -Path $Pasta -ChildPath "$Nome.ps1"
    Set-Content -LiteralPath $caminhoDoScript -Value "$importacaoDoModulo; `$input | WinPlaybook\Invoke-WinPlaybook '$Nome' @args; exit `$LASTEXITCODE" -Encoding UTF8

    $pastaDosScriptsDoExe = Join-Path -Path $Pasta -ChildPath 'exe'
    $null = New-Item -ItemType Directory -Path $pastaDosScriptsDoExe -Force
    $caminhoDoScriptDoExe = Join-Path -Path $pastaDosScriptsDoExe -ChildPath "$Nome.ps1"
    $decodificacaoDosArgumentos = '$argumentos = @($args | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_.Substring(1))) })'
    Set-Content -LiteralPath $caminhoDoScriptDoExe -Value "$importacaoDoModulo; $decodificacaoDosArgumentos; WinPlaybook\Invoke-WinPlaybook '$Nome' @argumentos; exit `$LASTEXITCODE" -Encoding UTF8

    Copy-Item -LiteralPath $CaminhoDoExecutavel -Destination (Join-Path -Path $Pasta -ChildPath "$Nome.exe") -Force

    Set-Content -LiteralPath (Join-Path -Path $Pasta -ChildPath "$Nome.shim") -Encoding UTF8 -Value @(
        "path = $CaminhoDoPowerShell"
        "args = -NoProfile -ExecutionPolicy Bypass -File `"$caminhoDoScriptDoExe`""
    )
}
