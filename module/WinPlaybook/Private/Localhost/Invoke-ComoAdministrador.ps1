function Invoke-ComoAdministrador {
    <#
    .SYNOPSIS
    Roda um comando do WinPlaybook num PowerShell elevado, que o Windows pede para o usuário aprovar, e espera ele terminar.

    .DESCRIPTION
    O PowerShell elevado é da mesma edição do atual, carrega o módulo pela mesma pasta e roda
    sem janela própria: só a aprovação do Windows aparece. Enquanto ele roda, a etapa em
    andamento mostra a parte do comando que o Write-ProgressoDoAdministrador contou, e a
    espera pode ser interrompida com Ctrl+C. Interrompida, a função avisa que o PowerShell
    elevado continua rodando, porque um processo comum não pode encerrar um elevado.

    Quando o comando falha, a mensagem do erro volta por um arquivo temporário e vira o erro
    desta função, para o usuário ver a causa na janela em que chamou o comando. Falha também
    quando o usuário recusa a elevação.

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

    $identificador = [guid]::NewGuid().ToString('N')
    $arquivoDoErro = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "WinPlaybook-erro-$identificador.txt"
    $arquivoDoProgresso = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "WinPlaybook-progresso-$identificador.txt"
    $pastaDoModulo = (Get-PastaDoModulo).Replace("'", "''")
    $script = "`$ErrorActionPreference = 'Stop'; `$env:WINPLAYBOOK_PROGRESS_FILE = '$($arquivoDoProgresso.Replace("'", "''"))'; try { Import-Module '$pastaDoModulo'; $Comando } catch { [IO.File]::WriteAllText('$($arquivoDoErro.Replace("'", "''"))', `$_.Exception.Message); exit 1 }"
    $comandoCodificado = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
    try {
        $processo = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $comandoCodificado -Verb RunAs -WindowStyle Hidden -PassThru
    }
    catch {
        throw (Get-Mensagem -Nome 'ElevacaoRecusada' -Valores $_.Exception.Message)
    }

    $ultimoProgresso = ''
    try {
        while (-not $processo.WaitForExit(250)) {
            $temProgresso = Test-Path -LiteralPath $arquivoDoProgresso -PathType Leaf
            if ($temProgresso) {
                $progresso = @(Get-Content -LiteralPath $arquivoDoProgresso -ErrorAction SilentlyContinue)[-1]
                $mudouOProgresso = $progresso -and $progresso -ne $ultimoProgresso
                if ($mudouOProgresso) {
                    $ultimoProgresso = $progresso
                    Set-TextoDaEtapa -Texto $progresso
                }
            }
        }
    }
    finally {
        $foiInterrompido = -not $processo.HasExited
        if ($foiInterrompido) {
            Stop-EtapaAtual
            Write-Warning (Get-Mensagem -Nome 'AdministradorContinuaRodando' -Valores $Comando)
        }
        Remove-Item -LiteralPath $arquivoDoProgresso -Force -ErrorAction SilentlyContinue
    }

    $terminouBem = $processo.ExitCode -eq 0
    if ($terminouBem) {
        return
    }

    $causa = ''
    $temCausa = Test-Path -LiteralPath $arquivoDoErro -PathType Leaf
    if ($temCausa) {
        $causa = [IO.File]::ReadAllText($arquivoDoErro).Trim()
        Remove-Item -LiteralPath $arquivoDoErro -Force -ErrorAction SilentlyContinue
    }
    throw (Get-Mensagem -Nome 'ComandoComoAdministradorFalhou' -Valores $Comando, $processo.ExitCode, $causa)
}
