function Get-PassoDoLocalhostWindows {
    <#
    .SYNOPSIS
    Devolve as etapas do plano para ligar ou desligar o localhost_windows.

    .DESCRIPTION
    As etapas ficam sob um título. A espera pela aprovação de administrador só entra quando o
    PowerShell atual não é de administrador. O Enable- e o Disable-WinPlaybookLocalhost usam
    estas etapas no plano deles, e o Install- e o Uninstall-WinPlaybook as incluem no plano
    deles, com os mesmos Ids, para as etapas aparecerem uma vez só.

    .PARAMETER Desligar
    Devolve as etapas para desligar. Sem ele, para ligar.

    .EXAMPLE
    $passos = Get-PassoDoLocalhostWindows
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [switch] $Desligar
    )

    $titulo = 'TituloLigarOLocalhostWindows'
    if ($Desligar) {
        $titulo = 'TituloDesligarOLocalhostWindows'
    }
    Write-Output @{ Id = 'localhost'; Texto = (Get-Mensagem -Nome $titulo); Titulo = $true }

    $precisaDeAprovacao = -not (Test-Administrador)
    if ($precisaDeAprovacao) {
        Write-Output @{ Id = 'localhost.aprovacao'; Texto = (Get-Mensagem -Nome 'PassoAguardarAAprovacao'); Recuo = 1 }
    }

    if ($Desligar) {
        Write-Output @{ Id = 'localhost.remover'; Texto = (Get-Mensagem -Nome 'PassoApagarOServico'); Recuo = 1 }
        return
    }
    Write-Output @{ Id = 'localhost.chave'; Texto = (Get-Mensagem -Nome 'PassoCriarAChave'); Recuo = 1 }
    Write-Output @{ Id = 'localhost.openssh'; Texto = (Get-Mensagem -Nome 'PassoBaixarOOpenSsh'); Recuo = 1 }
    Write-Output @{ Id = 'localhost.servico'; Texto = (Get-Mensagem -Nome 'PassoCriarOServico'); Recuo = 1 }
}
