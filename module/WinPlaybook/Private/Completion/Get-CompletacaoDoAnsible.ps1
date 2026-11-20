function Get-CompletacaoDoAnsible {
    <#
    .SYNOPSIS
    Devolve as opções que completam uma linha de comando do Ansible, uma por item.

    .DESCRIPTION
    Quando a palavra do cursor é uma opção, começando com -, pergunta ao argcomplete, uma vez
    por sessão, todas as opções do comando, das palavras anteriores e da pasta atual, e filtra
    as próximas pela palavra digitada. Para as outras palavras, como nomes de arquivos,
    pergunta ao argcomplete a cada vez.

    .PARAMETER Comando
    O comando do Ansible, como ansible-playbook.

    .PARAMETER Linha
    A linha até o cursor, começando pelo nome do comando, como "ansible-playbook --ch".

    .EXAMPLE
    Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook --ch'

    Devolve --check.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Comando,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Linha
    )

    $palavraAtual = $Linha.Substring($Linha.LastIndexOf(' ') + 1)
    $ehOpcao = $palavraAtual.StartsWith('-')
    if (-not $ehOpcao) {
        return Get-OpcaoDoArgcomplete -Comando $Comando -Linha $Linha
    }

    $opcoesGuardadas = Get-Variable -Name 'opcoesDoAutocomplete' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if ($null -eq $opcoesGuardadas) {
        $opcoesGuardadas = @{}
        $script:opcoesDoAutocomplete = $opcoesGuardadas
    }
    $contexto = $Linha.Substring(0, $Linha.Length - $palavraAtual.Length) + '-'
    $pastaAtual = (Get-Location -PSProvider FileSystem).ProviderPath
    $chave = "$Comando`n$pastaAtual`n$contexto"
    $contextoJaFoiConsultado = $opcoesGuardadas.ContainsKey($chave)
    if (-not $contextoJaFoiConsultado) {
        $opcoesGuardadas[$chave] = @(Get-OpcaoDoArgcomplete -Comando $Comando -Linha $contexto)
    }
    foreach ($opcao in $opcoesGuardadas[$chave]) {
        $completaAPalavra = $opcao.StartsWith($palavraAtual, [StringComparison]::Ordinal)
        if ($completaAPalavra) {
            Write-Output $opcao
        }
    }
}