function Show-AvisoDeAnsibleDoWindowsNaVenv {
    <#
    .SYNOPSIS
    Avisa no stderr quando a .venv do projeto tem um Ansible do Windows, que passa na frente dos comandos do WinPlaybook.

    .DESCRIPTION
    Procura o pyproject.toml na pasta atual e nas pastas acima dela. Quando a .venv ao lado
    dele tem o ansible.exe ou o ansible-playbook.exe, que um uv sync no Windows cria, mostra
    em amarelo a causa e como resolver. Não avisa quando o stderr não é o terminal, como num
    programa que lê a saída.

    .PARAMETER PastaAtual
    A pasta onde o comando roda.

    .EXAMPLE
    Show-AvisoDeAnsibleDoWindowsNaVenv -PastaAtual 'C:\infra\playbooks'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $PastaAtual
    )

    $naoHaTerminal = -not (Test-SaidaDeErroNoTerminal)
    if ($naoHaTerminal) {
        return
    }

    $pasta = $PastaAtual
    while ($pasta) {
        $temProjeto = Test-Path -LiteralPath (Join-Path -Path $pasta -ChildPath 'pyproject.toml') -PathType Leaf
        if ($temProjeto) {
            $pastaDosScripts = Join-Path -Path $pasta -ChildPath '.venv\Scripts'
            $temAnsibleDoWindows = @('ansible.exe', 'ansible-playbook.exe' | Where-Object { Test-Path -LiteralPath (Join-Path -Path $pastaDosScripts -ChildPath $_) -PathType Leaf }).Count -gt 0
            if ($temAnsibleDoWindows) {
                Write-LinhaColoridaNoErro -Texto (Get-Mensagem -Nome 'AnsibleDoWindowsNaVenv' -Valores (Join-Path -Path $pasta -ChildPath '.venv')) -Cor 'Yellow'
            }
            return
        }

        $pastaDeCima = Split-Path -Path $pasta -Parent
        $chegouNaRaiz = $pastaDeCima -eq $pasta
        if ($chegouNaRaiz) {
            return
        }
        $pasta = $pastaDeCima
    }
}
