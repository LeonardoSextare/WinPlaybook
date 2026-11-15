function Remove-EntradaDoPathDoUsuario {
    <#
    .SYNOPSIS
    Tira uma pasta do Path do usuário e do Path da sessão atual.

    .DESCRIPTION
    As outras entradas do Path do usuário ficam como estão, inclusive as que usam
    variáveis de ambiente, como %USERPROFILE%\bin. Quando a pasta é a única entrada, a
    variável é apagada.

    .PARAMETER Pasta
    A pasta que sai do Path.

    .PARAMETER NomeDaVariavel
    A variável de ambiente alterada. O padrão é Path.

    .EXAMPLE
    Remove-EntradaDoPathDoUsuario -Pasta 'C:\shims'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Pasta,
        [string] $NomeDaVariavel = 'Path'
    )

    $entradaDaPasta = $Pasta.TrimEnd('\')

    $valoresAtuais = @{
        Usuario = (Get-Item -LiteralPath 'HKCU:\Environment').GetValue($NomeDaVariavel, '', 'DoNotExpandEnvironmentNames')
        Sessao  = [Environment]::GetEnvironmentVariable($NomeDaVariavel, 'Process')
    }

    $pathPorEscopo = @{}
    foreach ($escopo in $valoresAtuais.Keys) {
        $entradas = @("$($valoresAtuais[$escopo])".Split(';') | Where-Object { $_ })
        $entradasQueFicam = @($entradas | Where-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') -ne $entradaDaPasta })
        $pathPorEscopo[$escopo] = @{
            TemPasta  = $entradasQueFicam.Count -lt $entradas.Count
            NovoValor = $entradasQueFicam -join ';'
        }
    }

    if ($pathPorEscopo.Usuario.TemPasta) {
        $eraAUnicaEntrada = -not $pathPorEscopo.Usuario.NovoValor
        if ($eraAUnicaEntrada) {
            Remove-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $NomeDaVariavel
        }
        else {
            $null = New-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $NomeDaVariavel -Value $pathPorEscopo.Usuario.NovoValor -PropertyType ExpandString -Force
        }
        Send-AvisoDeMudancaNoAmbiente
    }

    if ($pathPorEscopo.Sessao.TemPasta) {
        $eraAUnicaEntrada = -not $pathPorEscopo.Sessao.NovoValor
        if ($eraAUnicaEntrada) {
            Remove-Item -LiteralPath "Env:$NomeDaVariavel"
        }
        else {
            Set-Item -LiteralPath "Env:$NomeDaVariavel" -Value $pathPorEscopo.Sessao.NovoValor
        }
    }
}
