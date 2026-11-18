function Read-EscolhaDoLocalhostWindows {
    <#
    .SYNOPSIS
    Pergunta ao usuário se ele quer ligar o localhost_windows e devolve a resposta.

    .EXAMPLE
    Read-EscolhaDoLocalhostWindows

    Devolve $true quando o usuário escolhe Sim.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $opcoes = [Management.Automation.Host.ChoiceDescription[]] @(
        [Management.Automation.Host.ChoiceDescription]::new((Get-Mensagem -Nome 'OpcaoSim'), (Get-Mensagem -Nome 'OpcaoSimDoLocalhostWindows'))
        [Management.Automation.Host.ChoiceDescription]::new((Get-Mensagem -Nome 'OpcaoNao'), (Get-Mensagem -Nome 'OpcaoNaoDoLocalhostWindows'))
    )
    $escolha = $Host.UI.PromptForChoice((Get-Mensagem -Nome 'TituloDoLocalhostWindows'), (Get-Mensagem -Nome 'PerguntaDoLocalhostWindows'), $opcoes, 0)
    return $escolha -eq 0
}
