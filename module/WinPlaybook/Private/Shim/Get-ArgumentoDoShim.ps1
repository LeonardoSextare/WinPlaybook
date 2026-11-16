function Get-ArgumentoDoShim {
    <#
    .SYNOPSIS
    Devolve os argumentos de um comando como o programa que executou o shim os passou.

    .DESCRIPTION
    O .exe de um shim abre o PowerShell com -File, e o PowerShell separa em dois os
    argumentos que começam com - e têm dois-pontos, como --inventory=C:\hosts.yml e
    --limit=web:db. Quando o processo foi aberto para executar o shim do comando, os
    argumentos vêm do processo, que os recebeu sem mudança. Nos outros casos, os argumentos
    recebidos voltam como estão.

    .PARAMETER Comando
    O comando, como ansible-playbook. O shim dele é o script <comando>.ps1.

    .PARAMETER Argumentos
    Os argumentos do comando, como o PowerShell os entregou.

    .PARAMETER CaminhoDoChamador
    O script que chamou o comando, ou vazio quando ele foi digitado no terminal.

    .EXAMPLE
    Get-ArgumentoDoShim -Comando 'ansible-playbook' -Argumentos $argumentos -CaminhoDoChamador $MyInvocation.PSCommandPath

    Devolve --inventory=C:\hosts.yml e site.yml quando o .exe do shim recebeu esses argumentos.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [string] $Comando,
        [AllowEmptyCollection()] [AllowEmptyString()] [string[]] $Argumentos = @(),
        [AllowEmptyString()] [string] $CaminhoDoChamador
    )

    $ehOShimDoComando = [IO.Path]::GetFileNameWithoutExtension($CaminhoDoChamador) -eq $Comando
    if (-not $ehOShimDoComando) {
        return $Argumentos
    }

    $argumentosDoProcesso = @(Get-ArgumentoDoProcesso)
    for ($indice = 1; $indice -lt $argumentosDoProcesso.Count; $indice++) {
        $ehOScriptDoProcesso = ($argumentosDoProcesso[$indice - 1] -eq '-File') -and ($argumentosDoProcesso[$indice] -eq $CaminhoDoChamador)
        if ($ehOScriptDoProcesso) {
            return @($argumentosDoProcesso | Select-Object -Skip ($indice + 1))
        }
    }

    return $Argumentos
}
