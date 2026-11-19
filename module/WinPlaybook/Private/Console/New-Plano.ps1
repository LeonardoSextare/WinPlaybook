function New-Plano {
    <#
    .SYNOPSIS
    Mostra no console, de uma vez, todas as etapas que um comando vai executar, e devolve o plano para o Start- e o Complete-ItemDoPlano atualizarem.

    .DESCRIPTION
    Num terminal interativo, com uma janela de console em que o plano cabe, cada etapa aparece em cinza com
    [ ], e depois só o sinal dela muda: [|] girando enquanto roda, [+] em verde quando termina,
    [-] em amarelo numa remoção e [x] em vermelho numa falha. Um título agrupa as etapas
    recuadas abaixo dele. Fora disso, nada aparece agora, e cada etapa ganha a própria linha
    quando termina.

    Um plano criado com outro em andamento, como o de um comando que a instalação chama, não
    aparece: ele usa as etapas de mesmo Id do plano de fora, que já as mostrou. O Close-Plano
    do plano de dentro não fecha o de fora.

    .PARAMETER Itens
    As etapas, em ordem, cada uma com Id, Texto e, opcionalmente, Recuo (1 para uma etapa
    dentro de um título) e Titulo ($true para um título sem sinal).

    .EXAMPLE
    $plano = New-Plano -Itens @(@{ Id = 'ansible'; Texto = 'Instalar o Ansible' }, @{ Id = 'comandos'; Texto = 'Criar os comandos' })
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [hashtable[]] $Itens
    )

    $planoDeFora = Get-Variable -Name 'Plano' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $estaDentroDeOutro = $null -ne $planoDeFora
    if ($estaDentroDeOutro) {
        return @{ Aninhado = $true; Principal = $planoDeFora }
    }

    $etapas = [ordered]@{}
    $indice = 0
    foreach ($item in $Itens) {
        $etapas[$item.Id] = @{
            Indice  = $indice
            Texto   = $item.Texto
            Recuo   = [int] $item['Recuo']
            Titulo  = [bool] $item['Titulo']
            Relogio = $null
            Mostrou = $false
        }
        $indice++
    }

    $plano = @{ Aninhado = $false; Etapas = $etapas; Interativo = $false; PrimeiraLinha = 0; Animacao = $null; EmAndamento = $null }
    $plano.Principal = $plano
    $ehTerminal = (Test-SessaoInterativa) -and -not [Console]::IsOutputRedirected
    if ($ehTerminal) {
        try {
            $plano.Interativo = $etapas.Count -lt [Console]::WindowHeight
        }
        catch [IO.IOException] {
            $plano.Interativo = $false
        }
    }
    if ($plano.Interativo) {
        foreach ($etapa in $etapas.Values) {
            Write-LinhaDoPlano -Etapa $etapa -Marca ' ' -Cor 'DarkGray'
        }
        $plano.PrimeiraLinha = [Console]::CursorTop - $etapas.Count
    }

    $script:Plano = $plano
    return $plano
}
