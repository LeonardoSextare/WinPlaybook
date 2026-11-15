function Send-AvisoDeMudancaNoAmbiente {
    <#
    .SYNOPSIS
    Avisa os programas abertos, como o Explorer, que as variáveis de ambiente do usuário mudaram.

    .DESCRIPTION
    Sem o aviso, os terminais abertos pelo Explorer continuam recebendo o Path antigo até o
    próximo logon.

    .EXAMPLE
    Send-AvisoDeMudancaNoAmbiente

    .LINK
    https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-sendmessagetimeoutw

    .LINK
    https://learn.microsoft.com/windows/win32/winmsg/wm-settingchange
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $tipoEstaCarregado = [bool] ('WinPlaybook.NotificadorDeAmbiente' -as [type])
    if (-not $tipoEstaCarregado) {
        $declaracao = @(
            '[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]'
            'public static extern IntPtr SendMessageTimeout('
            '    IntPtr janela,'
            '    uint mensagem,'
            '    UIntPtr parametroNaoUsado,'
            '    string configuracaoAlterada,'
            '    uint opcoes,'
            '    uint tempoLimiteEmMilissegundos,'
            '    out UIntPtr resultado'
            ');'
        ) -join [Environment]::NewLine
        Add-Type -Namespace 'WinPlaybook' -Name 'NotificadorDeAmbiente' -MemberDefinition $declaracao
    }

    $todasAsJanelas = [IntPtr] 0xffff
    $mensagemDeConfiguracaoAlterada = 0x1A
    $desistirDeJanelaTravada = 2
    $esperaPorJanelaEmMilissegundos = 200
    $resultado = [UIntPtr]::Zero
    $null = [WinPlaybook.NotificadorDeAmbiente]::SendMessageTimeout(
        $todasAsJanelas,
        $mensagemDeConfiguracaoAlterada,
        [UIntPtr]::Zero,
        'Environment',
        $desistirDeJanelaTravada,
        $esperaPorJanelaEmMilissegundos,
        [ref] $resultado
    )
}
