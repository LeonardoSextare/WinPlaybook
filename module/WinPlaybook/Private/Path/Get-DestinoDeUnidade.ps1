function Get-DestinoDeUnidade {
    <#
    .SYNOPSIS
    Devolve a pasta real das unidades do Windows que o WSL não monta sozinho.

    .DESCRIPTION
    São as unidades criadas com o subst, que apontam para uma pasta de outra unidade, e as
    unidades de rede mapeadas, que apontam para um caminho de rede. Devolve uma hashtable
    com a letra em maiúscula, sem os dois-pontos, e a pasta para onde ela aponta.

    .EXAMPLE
    Get-DestinoDeUnidade

    Devolve @{ W = 'C:\Users\eu\infra'; Z = '\\servidor\infra' }, com W criada pelo subst e Z
    mapeada para \\servidor\infra.

    .LINK
    https://learn.microsoft.com/windows-server/administration/windows-commands/subst
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $destinos = @{}

    $ErrorActionPreference = 'Continue'
    foreach ($linha in @($null | subst.exe 2> $null)) {
        $ehUnidadeDoSubst = "$linha" -match '^(?<unidade>[A-Za-z]):\\: => (?<destino>.+)$'
        if ($ehUnidadeDoSubst) {
            $destinos[$Matches.unidade.ToUpperInvariant()] = $Matches.destino
        }
    }

    foreach ($unidade in @(Get-PSDrive -PSProvider FileSystem)) {
        $ehUnidadeDeRede = "$($unidade.DisplayRoot)".StartsWith('\\', [StringComparison]::Ordinal)
        if ($ehUnidadeDeRede) {
            $destinos[$unidade.Name.ToUpperInvariant()] = $unidade.DisplayRoot
        }
    }

    return $destinos
}
