function Get-Configuracao {
    <#
    .SYNOPSIS
    Devolve a configuração do WinPlaybook, com valores vazios no que ainda não foi salvo.

    .DESCRIPTION
    As chaves são ShimFolder, ShimPowerShellPath, WslDistribution, WslMountRoot, AnsibleVersion,
    PythonPackages e SshAgentPipe, o named pipe do agente SSH do Windows, que vazio é o
    openssh-ssh-agent.

    .EXAMPLE
    (Get-Configuracao).ShimFolder

    Devolve a pasta onde os shims foram instalados, ou $null.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $configuracao = @{
        ShimFolder         = $null
        ShimPowerShellPath = $null
        WslDistribution    = $null
        WslMountRoot       = $null
        AnsibleVersion     = $null
        PythonPackages     = $null
        SshAgentPipe       = $null
    }

    $caminhoDoArquivo = Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'settings.json'
    $existeArquivo = Test-Path -LiteralPath $caminhoDoArquivo
    if (-not $existeArquivo) {
        return $configuracao
    }

    $configuracaoSalva = Get-Content -LiteralPath $caminhoDoArquivo -Raw | ConvertFrom-Json
    foreach ($propriedade in $configuracaoSalva.PSObject.Properties) {
        $configuracao[$propriedade.Name] = $propriedade.Value
    }

    return $configuracao
}
