function Mount-PastaDoWindows {
    <#
    .SYNOPSIS
    Monta na distribuição as pastas do Windows que o WSL não monta sozinho.

    .DESCRIPTION
    Cada pasta é montada com as mesmas permissões das unidades que o WSL monta (pastas 755 e
    arquivos 644), com o usuário winplaybook como dono, e com as credenciais do usuário do
    Windows, no caso das pastas de rede. Uma pasta já montada fica como está. A montagem dura
    até a distribuição parar.

    .PARAMETER Distribuicao
    A distribuição WSL do WinPlaybook.

    .PARAMETER Montagem
    As pastas, como Get-MontagemNecessaria devolve, com Origem e PontoDeMontagem.

    .EXAMPLE
    Mount-PastaDoWindows -Distribuicao 'WinPlaybook' -Montagem ([pscustomobject]@{ Origem = 'W:'; PontoDeMontagem = '/mnt/w' })
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [pscustomobject[]] $Montagem
    )

    $script = @(
        'usuario="$1"; shift;'
        'opcoes="metadata,uid=$(id -u "$usuario"),gid=$(id -g "$usuario"),umask=22,fmask=111";'
        'while [ "$#" -gt 1 ]; do'
        'origem="$1"; ponto_de_montagem="$2"; shift 2;'
        'mountpoint -q "$ponto_de_montagem" && continue;'
        'mkdir -p "$ponto_de_montagem" && mount -t drvfs "$origem" "$ponto_de_montagem" -o "$opcoes" || exit 1;'
        'done'
    ) -join ' '

    $argumentos = @('winplaybook') + @(foreach ($item in $Montagem) { $item.Origem; $item.PontoDeMontagem })
    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Distribuicao -Script $script -Argumentos $argumentos -Usuario 'root'
    $montou = $resultado.CodigoDeSaida -eq 0
    if (-not $montou) {
        throw (Get-Mensagem -Nome 'PastaNaoMontada' -Valores (($Montagem.Origem) -join ', '), $resultado.Saida)
    }
}
