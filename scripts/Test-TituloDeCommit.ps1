#Requires -Version 7.4

<#
.SYNOPSIS
Confere se os títulos dos commits seguem a convenção do projeto.

.DESCRIPTION
Cada título precisa estar no formato <tipo>: <descrição> do Conventional Commits,
sem escopo e com um dos tipos aceitos. A descrição começa com letra minúscula, não
termina com ponto e tem até 72 caracteres.

O script mostra cada título fora da convenção, com o motivo, e falha se encontrar
algum.

.PARAMETER Intervalo
Os commits conferidos, no formato de intervalo do git log.

.EXAMPLE
./scripts/Test-TituloDeCommit.ps1

Confere os commits da branch atual que ainda não estão na origin/main.

.EXAMPLE
./scripts/Test-TituloDeCommit.ps1 -Intervalo 'main..minha-branch'

Confere os commits da minha-branch que ainda não estão na main.

.LINK
https://www.conventionalcommits.org/
#>
[CmdletBinding()]
param(
    [string] $Intervalo = 'origin/main..HEAD'
)

$ErrorActionPreference = 'Stop'

$tiposAceitos = 'feat', 'fix', 'perf', 'refactor', 'docs', 'style', 'test', 'build', 'ci', 'chore', 'revert'
$padraoDoTitulo = "^(?:$($tiposAceitos -join '|'))!?: (?<descricao>.+)$"
$tamanhoMaximoDaDescricao = 72

$titulos = @(git log --format=%s $Intervalo)
if ($LASTEXITCODE -ne 0) {
    throw "Não foi possível listar os commits do intervalo '$Intervalo'. Confira se as duas pontas existem, por exemplo com: git fetch origin"
}

$problemas = foreach ($titulo in $titulos) {
    $resultado = [regex]::Match($titulo, $padraoDoTitulo)
    if (-not $resultado.Success) {
        Write-Output "$titulo`n  fora do formato <tipo>: <descrição>, sem escopo. Tipos aceitos: $($tiposAceitos -join ', ')."
        continue
    }

    $descricao = $resultado.Groups['descricao'].Value
    $comecaComMinuscula = [char]::IsLower($descricao[0])
    if (-not $comecaComMinuscula) {
        Write-Output "$titulo`n  a descrição precisa começar com letra minúscula."
    }

    if ($descricao.EndsWith('.')) {
        Write-Output "$titulo`n  a descrição não pode terminar com ponto."
    }

    $descricaoEhLongaDemais = $descricao.Length -gt $tamanhoMaximoDaDescricao
    if ($descricaoEhLongaDemais) {
        Write-Output "$titulo`n  a descrição tem $($descricao.Length) caracteres, e o limite é $tamanhoMaximoDaDescricao."
    }
}

$temProblemas = @($problemas).Count -gt 0
if ($temProblemas) {
    Write-Host ($problemas -join "`n`n")
    Write-Host ''
    throw "Há $(@($problemas).Count) problema(s) nos títulos de commit acima. A convenção está no AGENTS.md, seção Commits e histórico. Reescreva os títulos com git rebase -i origin/main (opção reword) e envie com git push --force-with-lease."
}

Write-Host "Títulos de commit conferidos: $($titulos.Count), todos dentro da convenção do projeto."
