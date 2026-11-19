function Get-EscolhaDaInstalacao {
    <#
    .SYNOPSIS
    Pergunta, antes da instalação começar, se o usuário quer ligar o localhost_windows e corrigir a extensão Ansible do VS Code.

    .DESCRIPTION
    As perguntas aparecem só num terminal interativo e só quando fazem sentido: a do
    localhost_windows, se ele ainda não está ligado e não foi recusado antes; a do VS Code,
    se a extensão Ansible (redhat.ansible) está instalada e ainda não foi corrigida. Os
    switches ligam a escolha sem perguntar. Uma recusa do localhost_windows fica na
    configuração recebida, em LocalhostWindowsDeclined, para a instalação gravar.

    Devolve LigarLocalhost e CorrigirVSCode.

    .PARAMETER Configuracao
    A configuração atual do WinPlaybook, de Get-Configuracao.

    .PARAMETER LigarLocalhost
    Liga o localhost_windows sem perguntar.

    .PARAMETER CorrigirVSCode
    Corrige a extensão do VS Code sem perguntar.

    .EXAMPLE
    $escolhas = Get-EscolhaDaInstalacao -Configuracao (Get-Configuracao)
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [hashtable] $Configuracao,
        [switch] $LigarLocalhost,
        [switch] $CorrigirVSCode
    )

    $escolhas = @{ LigarLocalhost = [bool] $LigarLocalhost; CorrigirVSCode = [bool] $CorrigirVSCode }
    $podePerguntar = Test-SessaoInterativa

    $localhostJaEstaLigado = [bool] $Configuracao['LocalhostWindowsPort']
    $perguntaDoLocalhost = $podePerguntar -and -not $LigarLocalhost -and -not $localhostJaEstaLigado -and -not $Configuracao['LocalhostWindowsDeclined']
    if ($perguntaDoLocalhost) {
        $escolhas.LigarLocalhost = Read-Escolha -Pergunta (Get-Mensagem -Nome 'PerguntaDoLocalhostWindows') -Explicacao (Get-Mensagem -Nome 'ExplicacaoDoLocalhostWindows') -Link (Get-Mensagem -Nome 'PaginaDaDocumentacao' -Valores 'localhost-windows') -AjudaDoSim (Get-Mensagem -Nome 'OpcaoSimDoLocalhostWindows') -AjudaDoNao (Get-Mensagem -Nome 'OpcaoNaoDoLocalhostWindows')
        if (-not $escolhas.LigarLocalhost) {
            $Configuracao['LocalhostWindowsDeclined'] = $true
        }
    }
    if ($localhostJaEstaLigado) {
        $escolhas.LigarLocalhost = $false
    }

    $extensoes = @(Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes (Get-PastaDasExtensoesDoVSCode))
    $extensaoJaFoiCorrigida = @($extensoes | Where-Object { Test-ExtensaoAnsibleCorrigida -Caminho $_.Caminho }).Count -gt 0
    $perguntaDoVSCode = $podePerguntar -and -not $CorrigirVSCode -and $extensoes.Count -gt 0 -and -not $extensaoJaFoiCorrigida
    if ($perguntaDoVSCode) {
        $escolhas.CorrigirVSCode = Read-Escolha -Pergunta (Get-Mensagem -Nome 'PerguntaDoVSCode') -Explicacao (Get-Mensagem -Nome 'ExplicacaoDoVSCode') -Link (Get-Mensagem -Nome 'PaginaDaDocumentacao' -Valores 'vscode') -AjudaDoSim (Get-Mensagem -Nome 'OpcaoSimDoVSCode') -AjudaDoNao (Get-Mensagem -Nome 'OpcaoNaoDoVSCode')
    }

    return $escolhas
}
