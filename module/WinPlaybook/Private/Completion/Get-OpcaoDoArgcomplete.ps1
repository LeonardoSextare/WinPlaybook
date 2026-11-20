function Get-OpcaoDoArgcomplete {
    <#
    .SYNOPSIS
    Pede ao argcomplete do Ansible as opções que completam uma linha de comando e devolve uma por item.

    .DESCRIPTION
    Na distribuição, roda o comando do Ansible no modo de autocomplete do argcomplete, com a
    linha e a posição do cursor, pelo Python do próprio comando: o do ambiente global ou o
    do ambiente do projeto da pasta atual. O comando não executa nada além do autocomplete.
    Quando o ambiente não tem o argcomplete, ou o comando não é um script Python, não
    devolve nada.

    .PARAMETER Comando
    O comando do Ansible, como ansible-playbook.

    .PARAMETER Linha
    A linha até o cursor, começando pelo nome do comando, como "ansible-playbook --ch".

    .EXAMPLE
    Get-OpcaoDoArgcomplete -Comando 'ansible-playbook' -Linha 'ansible-playbook --ch'

    Devolve --check.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Comando,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Linha
    )

    $codigo = @(
        'import os, shutil, subprocess, sys, tempfile'
        'comando, linha = sys.argv[1], sys.argv[2]'
        'caminho = shutil.which(comando)'
        'primeira_linha = open(caminho, "rb").readline() if caminho else b""'
        'if primeira_linha.startswith(b"#!"):'
        '    descritor, saida = tempfile.mkstemp()'
        '    os.close(descritor)'
        '    ambiente = dict(os.environ, _ARGCOMPLETE="1", _ARGCOMPLETE_IFS="\n", _ARGCOMPLETE_STDOUT_FILENAME=saida, COMP_LINE=linha, COMP_POINT=str(len(linha.encode())))'
        '    autocomplete = "import argcomplete, runpy, sys; caminho = sys.argv[1]; sys.argv = [caminho]; runpy.run_path(caminho, run_name=\"__main__\")"'
        '    subprocess.run(primeira_linha[2:].decode().split() + ["-c", autocomplete, caminho], env=ambiente, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)'
        '    print(open(saida, encoding="utf-8").read())'
        '    os.remove(saida)'
    ) -join "`n"

    $saida = Invoke-ComandoNoWsl -Comando '/usr/bin/python3' -Argumentos '-c', $codigo, $Comando, $Linha 2>$null
    foreach ($opcao in @($saida -split "`n")) {
        $temOpcao = [bool] $opcao.Trim()
        if ($temOpcao) {
            Write-Output $opcao.Trim()
        }
    }
}
