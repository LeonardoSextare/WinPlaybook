function Add-EntradaNoPathDoUsuario {
    <#
    .SYNOPSIS
    Coloca uma pasta no começo do Path do usuário e do Path da sessão atual.

    .DESCRIPTION
    O Path do usuário continua gravado como texto expansível, então entradas como
    %USERPROFILE%\bin continuam funcionando. No Path da sessão, a pasta fica disponível
    na hora, no terminal atual. Quando a pasta já está num dos dois, ele fica como está.

    .PARAMETER Pasta
    A pasta que entra no Path.

    .PARAMETER NomeDaVariavel
    A variável de ambiente alterada. O padrão é Path.

    .EXAMPLE
    Add-EntradaNoPathDoUsuario -Pasta 'C:\shims'
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
        $entradasExpandidas = $entradas | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }
        $pathPorEscopo[$escopo] = @{
            TemPasta  = $entradasExpandidas -contains $entradaDaPasta
            NovoValor = (@($Pasta) + $entradas) -join ';'
        }
    }

    if (-not $pathPorEscopo.Usuario.TemPasta) {
        $null = New-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $NomeDaVariavel -Value $pathPorEscopo.Usuario.NovoValor -PropertyType ExpandString -Force
        Send-AvisoDeMudancaNoAmbiente
    }

    if (-not $pathPorEscopo.Sessao.TemPasta) {
        Set-Item -LiteralPath "Env:$NomeDaVariavel" -Value $pathPorEscopo.Sessao.NovoValor
    }
}
