function Install-PatchDaExtensaoAnsible {
    <#
    .SYNOPSIS
    Aplica as trocas de Get-PatchDaExtensaoAnsible a uma pasta da extensão Ansible do VS Code.

    .DESCRIPTION
    Antes de alterar um arquivo, guarda o original ao lado dele, com a extensão
    .winplaybook-original, para o Remove-PatchDaExtensaoAnsible desfazer. Uma troca que já
    foi feita não é feita de novo. Se um arquivo não tem o trecho esperado, nada é alterado
    e o comando falha.

    .PARAMETER Caminho
    A pasta da extensão, como C:\Users\<usuário>\.vscode\extensions\redhat.ansible-26.11.0.

    .PARAMETER Trocas
    As trocas da versão da extensão, de Get-PatchDaExtensaoAnsible.

    .PARAMETER Versao
    A versão testada da extensão, para a mensagem de erro.

    .EXAMPLE
    Install-PatchDaExtensaoAnsible -Caminho $extensao.Caminho -Trocas (Get-PatchDaExtensaoAnsible)['26.11.0'] -Versao '26.11.0'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Caminho,
        [Parameter(Mandatory)] [hashtable[]] $Trocas,
        [Parameter(Mandatory)] [string] $Versao
    )

    $pastaDoServidor = Join-Path -Path $Caminho -ChildPath 'packages\ansible-language-server\dist'
    $textos = @{}
    foreach ($troca in $Trocas) {
        $caminhoDoArquivo = Join-Path -Path $pastaDoServidor -ChildPath $troca.Arquivo
        $arquivoAindaNaoFoiLido = -not $textos.ContainsKey($caminhoDoArquivo)
        if ($arquivoAindaNaoFoiLido) {
            $textos[$caminhoDoArquivo] = [IO.File]::ReadAllText($caminhoDoArquivo)
        }
        $jaFoiTrocado = $textos[$caminhoDoArquivo].Contains($troca.Para)
        if ($jaFoiTrocado) {
            continue
        }
        $temOTrecho = $textos[$caminhoDoArquivo].Contains($troca.De)
        if (-not $temOTrecho) {
            throw (Get-Mensagem -Nome 'PatchDaExtensaoAnsibleNaoAplicado' -Valores $Caminho, $troca.Arquivo, $Versao)
        }
        $textos[$caminhoDoArquivo] = $textos[$caminhoDoArquivo].Replace($troca.De, $troca.Para)
    }

    foreach ($caminhoDoArquivo in $textos.Keys) {
        $caminhoDoOriginal = "$caminhoDoArquivo.winplaybook-original"
        $originalJaFoiGuardado = Test-Path -LiteralPath $caminhoDoOriginal -PathType Leaf
        if (-not $originalJaFoiGuardado) {
            Copy-Item -LiteralPath $caminhoDoArquivo -Destination $caminhoDoOriginal
        }
        [IO.File]::WriteAllText($caminhoDoArquivo, $textos[$caminhoDoArquivo])
    }
}
