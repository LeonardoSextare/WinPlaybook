#Requires -Version 7.4

<#
.SYNOPSIS
Mede os cenários típicos pelo WinPlaybook instalado e pelo Ansible direto na distribuição, lado a lado.

.DESCRIPTION
Cada cenário roda pelos .exe da pasta dos shims, como um programa do Windows os chama, e
direto na distribuição do WinPlaybook, numa cópia do projeto no disco do Linux. O tempo do
lado nativo é medido dentro da distribuição, sem a abertura do wsl.exe. A diferença entre
os dois é o custo do WinPlaybook.

Os cenários são o ansible --version, um playbook local com muitas tarefas e um inventário
com muitos hosts de conexão local. Com -AlvoSsh, entra também um playbook por SSH nesse
alvo, que precisa aceitar a chave do agente SSH ou da pasta .ssh do Windows.

Precisa do WinPlaybook instalado com o Install-WinPlaybook.

.PARAMETER Repeticoes
Quantas vezes cada cenário roda de cada lado. O resultado mostra o mínimo e a mediana.

.PARAMETER AlvoSsh
Um alvo Linux por SSH, como deploy@192.168.0.10 ou deploy@localhost:2222.

.EXAMPLE
./scripts/dev/Measure-WinPlaybook.ps1

.EXAMPLE
./scripts/dev/Measure-WinPlaybook.ps1 -Repeticoes 10 -AlvoSsh 'deploy@localhost:2222'
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 100)] [int] $Repeticoes = 5,
    [string] $AlvoSsh
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$caminhoDaConfiguracao = Join-Path $env:LOCALAPPDATA 'WinPlaybook\settings.json'
if (-not (Test-Path -LiteralPath $caminhoDaConfiguracao)) {
    throw 'O WinPlaybook não está instalado. Rode o Install-WinPlaybook antes.'
}
$configuracao = Get-Content -LiteralPath $caminhoDaConfiguracao -Raw | ConvertFrom-Json
$distribuicao = $configuracao.WslDistribution
$pastaDosShims = $configuracao.ShimFolder

$pastaDoProjeto = Join-Path ([IO.Path]::GetTempPath()) "winplaybook-medicao-$([guid]::NewGuid().ToString('N'))"
$null = New-Item -ItemType Directory -Path $pastaDoProjeto

$tarefas = 1..20 | ForEach-Object { "    - name: Tarefa $_`n      ansible.builtin.set_fact:`n        valor_$_`: $_" }
Set-Content -LiteralPath (Join-Path $pastaDoProjeto 'local.yml') -Value "- hosts: localhost`n  connection: local`n  gather_facts: false`n  tasks:`n$($tarefas -join "`n")"
$hosts = 1..30 | ForEach-Object { "host$_ ansible_connection=local" }
Set-Content -LiteralPath (Join-Path $pastaDoProjeto 'muitos-hosts.ini') -Value "[todos]`n$($hosts -join "`n")"
Set-Content -LiteralPath (Join-Path $pastaDoProjeto 'hosts.yml') -Value "- hosts: all`n  gather_facts: false`n  tasks:`n    - ansible.builtin.ping:`n    - ansible.builtin.set_fact:`n        x: 1"

$cenarios = [Collections.Generic.List[hashtable]]::new()
$cenarios.Add(@{ Nome = 'ansible --version'; Comando = 'ansible'; Argumentos = @('--version') })
$cenarios.Add(@{ Nome = 'playbook local, 20 tarefas'; Comando = 'ansible-playbook'; Argumentos = @('local.yml') })
$cenarios.Add(@{ Nome = '30 hosts locais, 2 tarefas'; Comando = 'ansible-playbook'; Argumentos = @('-i', 'muitos-hosts.ini', 'hosts.yml') })
if ($AlvoSsh) {
    $usuario, $endereco = $AlvoSsh.Split('@', 2)
    $servidor, $porta = $endereco.Split(':', 2)
    $linhaDoAlvo = "alvo ansible_host=$servidor ansible_user=$usuario"
    if ($porta) {
        $linhaDoAlvo += " ansible_port=$porta"
    }
    Set-Content -LiteralPath (Join-Path $pastaDoProjeto 'ssh.ini') -Value "[todos]`n$linhaDoAlvo ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'"
    $cenarios.Add(@{ Nome = "SSH em $AlvoSsh, 2 tarefas"; Comando = 'ansible-playbook'; Argumentos = @('-i', 'ssh.ini', 'hosts.yml') })
}

function Get-Mediana {
    <#
    .SYNOPSIS
    Devolve a mediana de uma lista de números.

    .PARAMETER Valores
    Os números.

    .EXAMPLE
    Get-Mediana -Valores 3, 1, 2
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)] [double[]] $Valores
    )

    $ordenados = @($Valores | Sort-Object)
    $meio = [math]::Floor($ordenados.Count / 2)
    if ($ordenados.Count % 2 -eq 1) {
        return $ordenados[$meio]
    }
    return ($ordenados[$meio - 1] + $ordenados[$meio]) / 2
}

$pastaNoLinux = "/tmp/winplaybook-medicao-$([guid]::NewGuid().ToString('N'))"
$env:WSL_UTF8 = '1'
& wsl.exe --distribution $distribuicao --exec sh -c 'mkdir -p "$1" && cp -R --no-preserve=mode "$(wslpath -a "$0")/." "$1"' $pastaDoProjeto $pastaNoLinux
if ($LASTEXITCODE -ne 0) {
    throw "Não foi possível copiar o projeto para a distribuição $distribuicao."
}

$medicaoNativa = 'inicio=$(date +%s%N); "$@" > /dev/null 2>&1; codigo=$?; fim=$(date +%s%N); echo "$(( (fim - inicio) / 1000000 )) $codigo"'
$resultados = foreach ($cenario in $cenarios) {
    Write-Host "Medindo: $($cenario.Nome)"
    $caminhoDoExe = Join-Path $pastaDosShims "$($cenario.Comando).exe"
    $temposDoWinPlaybook = [Collections.Generic.List[double]]::new()
    $temposNativos = [Collections.Generic.List[double]]::new()
    Push-Location -LiteralPath $pastaDoProjeto
    try {
        $null = & $caminhoDoExe @($cenario.Argumentos) 2>&1
        foreach ($repeticao in 1..$Repeticoes) {
            $relogio = [Diagnostics.Stopwatch]::StartNew()
            $saida = & $caminhoDoExe @($cenario.Argumentos) 2>&1
            $relogio.Stop()
            if ($LASTEXITCODE -ne 0) {
                throw "$($cenario.Nome) falhou pelo WinPlaybook:`n$($saida -join "`n")"
            }
            $temposDoWinPlaybook.Add($relogio.Elapsed.TotalMilliseconds)
        }
    }
    finally {
        Pop-Location
    }

    foreach ($repeticao in 0..$Repeticoes) {
        $medida = & wsl.exe --distribution $distribuicao --cd $pastaNoLinux --exec sh -lc $medicaoNativa sh $cenario.Comando @($cenario.Argumentos)
        $milissegundos, $codigo = "$medida".Trim().Split(' ')
        if ($codigo -ne '0') {
            throw "$($cenario.Nome) falhou direto na distribuição, com o código $codigo."
        }
        if ($repeticao -gt 0) {
            $temposNativos.Add([double] $milissegundos)
        }
    }

    $medianaDoWinPlaybook = Get-Mediana -Valores $temposDoWinPlaybook
    $medianaNativa = Get-Mediana -Valores $temposNativos
    [pscustomobject]@{
        'Cenário'               = $cenario.Nome
        'WinPlaybook (mínimo)'  = [int] ($temposDoWinPlaybook | Measure-Object -Minimum).Minimum
        'WinPlaybook (mediana)' = [int] $medianaDoWinPlaybook
        'Nativo (mínimo)'       = [int] ($temposNativos | Measure-Object -Minimum).Minimum
        'Nativo (mediana)'      = [int] $medianaNativa
        'Custo (mediana)'       = [int] ($medianaDoWinPlaybook - $medianaNativa)
    }
}

& wsl.exe --distribution $distribuicao --exec rm -rf -- $pastaNoLinux
Remove-Item -LiteralPath $pastaDoProjeto -Recurse -Force

Write-Host "`nTempos em ms, $Repeticoes repetições de cada lado:"
$resultados | Format-Table -AutoSize
