function Register-WinPlaybookArgumentCompleter {
    <#
    .SYNOPSIS
    Liga o autocomplete dos comandos do Ansible no PowerShell.

    .DESCRIPTION
    Registra um completer para cada comando que tem shim na pasta dos shims do WinPlaybook,
    pelo nome curto, com .exe e com .ps1. No Tab, o completer pede ao argcomplete do Ansible,
    na distribuição, as opções que completam a linha, como as opções do comando e os
    subcomandos do ansible-galaxy. Quando o argcomplete não devolve nada, o PowerShell
    completa os caminhos, como em qualquer comando. O Install-WinPlaybook acrescenta uma
    chamada a este comando ao perfil do PowerShell, e o autocomplete vale desde o primeiro
    Tab de um terminal novo.

    .EXAMPLE
    Register-WinPlaybookArgumentCompleter

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.core/register-argumentcompleter
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $pastaDosShims = (Get-Configuracao).ShimFolder
    $temPastaDosShims = $pastaDosShims -and (Test-Path -LiteralPath $pastaDosShims -PathType Container)
    if (-not $temPastaDosShims) {
        return
    }

    $comandos = @(Get-ChildItem -LiteralPath $pastaDosShims -Filter '*.ps1' -File | ForEach-Object { $_.BaseName })
    $temComandos = $comandos.Count -gt 0
    if (-not $temComandos) {
        return
    }

    $completar = {
        param($palavra, $ast, $posicaoDoCursor)
        $primeiroElemento = $ast.CommandElements[0].Extent.Text
        $comando = [IO.Path]::GetFileNameWithoutExtension($primeiroElemento)
        $fimDaLinha = $posicaoDoCursor - $ast.Extent.StartOffset
        $texto = $ast.Extent.Text.PadRight($fimDaLinha)
        $linha = $comando + $texto.Substring($primeiroElemento.Length, $fimDaLinha - $primeiroElemento.Length)
        foreach ($opcao in Get-CompletacaoDoAnsible -Comando $comando -Linha $linha) {
            Write-Output ([Management.Automation.CompletionResult]::new($opcao, $opcao, 'ParameterValue', $opcao))
        }
    }
    $nomes = $comandos + @($comandos | ForEach-Object { "$_.exe"; "$_.ps1" })
    Register-ArgumentCompleter -Native -CommandName $nomes -ScriptBlock $completar
}
