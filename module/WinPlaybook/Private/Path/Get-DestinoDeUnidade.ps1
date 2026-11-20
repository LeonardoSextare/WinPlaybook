function Get-DestinoDeUnidade {
    <#
    .SYNOPSIS
    Devolve a pasta real das unidades do Windows que o WSL não monta sozinho.

    .DESCRIPTION
    São as unidades criadas com o subst, que apontam para uma pasta de outra unidade, e as
    unidades de rede mapeadas, que apontam para um caminho de rede. Devolve uma hashtable
    com a letra em maiúscula, sem os dois-pontos, e a pasta para onde ela aponta. Só procura
    quando os textos citam uma unidade além da unidade do sistema.

    .PARAMETER Texto
    Os textos que o comando vai converter, como a pasta atual, os argumentos e os valores das
    variáveis de ambiente.

    .EXAMPLE
    Get-DestinoDeUnidade -Texto 'W:\site.yml', 'Z:\hosts.yml'

    Devolve @{ W = 'C:\Users\eu\infra'; Z = '\\servidor\infra' }, com W criada pelo subst e Z
    mapeada para \\servidor\infra.

    .LINK
    https://learn.microsoft.com/windows-server/administration/windows-commands/subst
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [AllowEmptyString()] [AllowNull()] [string[]] $Texto
    )

    $destinos = @{}

    $unidadeDoSistema = [regex]::Escape("$env:SystemDrive".TrimEnd(':'))
    $citaOutraUnidade = [regex]::IsMatch(($Texto -join "`n"), "(?<![A-Za-z0-9])(?!$unidadeDoSistema`:)[A-Za-z]:", 'IgnoreCase')
    if (-not $citaOutraUnidade) {
        return $destinos
    }

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
