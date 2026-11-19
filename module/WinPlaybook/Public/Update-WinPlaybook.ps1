function Update-WinPlaybook {
    <#
    .SYNOPSIS
    Atualiza o WinPlaybook e o Ansible.

    .DESCRIPTION
    Atualiza o módulo WinPlaybook pela PowerShell Gallery e roda o Install-WinPlaybook da
    versão nova, que atualiza o Ansible e os shims e mantém as escolhas salvas, como a
    versão do Ansible e os pacotes Python. Quem instalou o módulo pelo código-fonte atualiza
    o código e roda o Install-WinPlaybook.

    O WinPlaybook avisa quando existe uma versão nova, na primeira vez que um comando roda
    na sessão do terminal. Para desligar o aviso, defina a variável de ambiente
    WINPLAYBOOK_UPDATE_CHECK como off.

    .EXAMPLE
    Update-WinPlaybook

    .LINK
    https://leonardosextare.github.io/WinPlaybook/pt-br/update-winplaybook/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    $confirmou = $PSCmdlet.ShouldProcess('WinPlaybook', (Get-Mensagem -Nome 'AtualizarWinPlaybook'))
    if (-not $confirmou) {
        return
    }

    $versaoAtual = $MyInvocation.MyCommand.Module.Version
    $plano = New-Plano -Itens @{ Id = 'versao'; Texto = (Get-Mensagem -Nome 'PassoProcurarAVersao') }
    try {
        Start-ItemDoPlano -Plano $plano -Id 'versao'
        try {
            $versaoMaisNova = Get-VersaoMaisNovaDoWinPlaybook
        }
        catch {
            throw (Get-Mensagem -Nome 'ModuloNaoAtualizado' -Valores $_.Exception.Message)
        }
        Complete-ItemDoPlano -Plano $plano -Id 'versao'
    }
    finally {
        Close-Plano -Plano $plano
    }

    $jaEstaAtualizado = $versaoMaisNova -le $versaoAtual
    if ($jaEstaAtualizado) {
        Write-Host (Get-Mensagem -Nome 'JaEstaAtualizado' -Valores $versaoAtual) -ForegroundColor Green
        return
    }

    $plano = New-Plano -Itens @{ Id = 'modulo'; Texto = (Get-Mensagem -Nome 'PassoBaixarOWinPlaybook' -Valores $versaoMaisNova) }
    try {
        Start-ItemDoPlano -Plano $plano -Id 'modulo'
        try {
            Update-ModuloDoWinPlaybook
        }
        catch {
            throw (Get-Mensagem -Nome 'ModuloNaoAtualizado' -Valores $_.Exception.Message)
        }
        Complete-ItemDoPlano -Plano $plano -Id 'modulo'
    }
    finally {
        Close-Plano -Plano $plano
    }

    Invoke-InstalacaoDaVersaoNova
    Write-Host (Get-Mensagem -Nome 'AtualizacaoConcluida' -Valores $versaoMaisNova) -ForegroundColor Green
}
