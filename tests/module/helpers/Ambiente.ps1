function New-NomeDeVariavelDeTeste {
    <#
    .SYNOPSIS
    Devolve um nome novo para uma variável de ambiente descartável dos testes.

    .EXAMPLE
    New-NomeDeVariavelDeTeste

    Devolve WINPLAYBOOK_TEST_ seguido de um GUID sem hifens.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return "WINPLAYBOOK_TEST_$([guid]::NewGuid().ToString('N'))"
}

function Set-VariavelDeUsuarioDeTeste {
    <#
    .SYNOPSIS
    Grava uma variável de ambiente do usuário como texto expansível, como o Windows grava o Path.

    .PARAMETER Nome
    O nome da variável, de New-NomeDeVariavelDeTeste.

    .PARAMETER Valor
    O valor gravado, sem expandir as variáveis que ele usa.

    .EXAMPLE
    Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor '%USERPROFILE%\bin'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $Valor
    )

    $null = New-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $Nome -Value $Valor -PropertyType ExpandString -Force
}

function Get-VariavelDeUsuarioDeTeste {
    <#
    .SYNOPSIS
    Devolve o valor sem expandir (Valor) e o tipo no registro (Tipo) de uma variável de ambiente do usuário.

    .DESCRIPTION
    Devolve $null quando a variável não existe.

    .PARAMETER Nome
    O nome da variável.

    .EXAMPLE
    (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Valor
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $Nome
    )

    $chaveDoAmbiente = Get-Item -LiteralPath 'HKCU:\Environment'
    $existeVariavel = $chaveDoAmbiente.GetValueNames() -contains $Nome
    if (-not $existeVariavel) {
        return $null
    }

    return [pscustomobject]@{
        Valor = $chaveDoAmbiente.GetValue($Nome, $null, 'DoNotExpandEnvironmentNames')
        Tipo  = $chaveDoAmbiente.GetValueKind($Nome).ToString()
    }
}

function Remove-VariavelDeTeste {
    <#
    .SYNOPSIS
    Apaga uma variável de ambiente de teste do usuário e da sessão atual.

    .PARAMETER Nome
    O nome da variável.

    .EXAMPLE
    Remove-VariavelDeTeste -Nome $nomeDaVariavel
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome
    )

    Remove-ItemProperty -LiteralPath 'HKCU:\Environment' -Name $Nome -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "Env:$Nome" -ErrorAction SilentlyContinue
}

function Clear-VariavelDeTeste {
    <#
    .SYNOPSIS
    Apaga todas as variáveis de ambiente de teste do usuário, inclusive as que sobraram de execuções interrompidas.

    .EXAMPLE
    Clear-VariavelDeTeste
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $nomesDasVariaveis = (Get-Item -LiteralPath 'HKCU:\Environment').GetValueNames() |
        Where-Object { $_.StartsWith('WINPLAYBOOK_TEST_') }
    foreach ($nome in $nomesDasVariaveis) {
        Remove-VariavelDeTeste -Nome $nome
    }
}
