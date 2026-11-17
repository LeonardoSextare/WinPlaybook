function Get-MontagemNecessaria {
    <#
    .SYNOPSIS
    Lista os compartilhamentos de rede que a distribuição precisa montar para os caminhos de um comando.

    .DESCRIPTION
    Procura nos textos, já convertidos para a distribuição, os caminhos de rede, que
    ConvertTo-CaminhoDoWsl põe em unc/<servidor>/<compartilhamento> dentro da raiz de
    montagem. O caminho pode estar no meio do texto, como em
    --inventory=/mnt/unc/servidor/infra/hosts.yml. Devolve um objeto por compartilhamento,
    sem repetir, com Origem, como o Windows o chama (\\servidor\infra), e PontoDeMontagem, na
    distribuição.

    .PARAMETER Texto
    Os textos que o comando recebe na distribuição, como a pasta atual e os argumentos.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .EXAMPLE
    Get-MontagemNecessaria -Texto '--inventory=/mnt/unc/servidor/infra/hosts.yml' -RaizDeMontagem '/mnt/'

    Devolve \\servidor\infra em /mnt/unc/servidor/infra.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [AllowEmptyString()] [string[]] $Texto,
        [Parameter(Mandatory)] [string] $RaizDeMontagem
    )

    $raizDaRede = $RaizDeMontagem.TrimEnd('/') + '/unc/'
    $padrao = [regex]::Escape($raizDaRede) + '(?<servidor>[^/:,]+)/(?<compartilhamento>[^/:,]+)'

    $montagens = [ordered]@{}
    foreach ($item in $Texto) {
        foreach ($ocorrencia in [regex]::Matches($item, $padrao)) {
            $servidor = $ocorrencia.Groups['servidor'].Value
            $compartilhamento = $ocorrencia.Groups['compartilhamento'].Value
            $montagens[$raizDaRede + $servidor + '/' + $compartilhamento] = '\\' + $servidor + '\' + $compartilhamento
        }
    }

    foreach ($pontoDeMontagem in $montagens.Keys) {
        Write-Output ([pscustomobject]@{ Origem = $montagens[$pontoDeMontagem]; PontoDeMontagem = $pontoDeMontagem })
    }
}
