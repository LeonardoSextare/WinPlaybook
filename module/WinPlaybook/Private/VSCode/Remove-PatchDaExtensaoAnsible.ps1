function Remove-PatchDaExtensaoAnsible {
    <#
    .SYNOPSIS
    Desfaz as trocas do WinPlaybook numa pasta da extensão Ansible do VS Code, voltando os arquivos originais.

    .DESCRIPTION
    Cada arquivo com um .winplaybook-original ao lado volta a ser o original, e a cópia é
    apagada. Uma pasta sem as trocas fica como está.

    .PARAMETER Caminho
    A pasta da extensão, como C:\Users\<usuário>\.vscode\extensions\redhat.ansible-26.11.0.

    .EXAMPLE
    Remove-PatchDaExtensaoAnsible -Caminho $extensao.Caminho
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Caminho
    )

    $pastaDoServidor = Join-Path -Path $Caminho -ChildPath 'packages\ansible-language-server\dist'
    $pastaExiste = Test-Path -LiteralPath $pastaDoServidor -PathType Container
    if (-not $pastaExiste) {
        return
    }

    foreach ($original in Get-ChildItem -LiteralPath $pastaDoServidor -Filter '*.winplaybook-original' -Recurse -File) {
        $caminhoDoArquivo = $original.FullName.Substring(0, $original.FullName.Length - '.winplaybook-original'.Length)
        Move-Item -LiteralPath $original.FullName -Destination $caminhoDoArquivo -Force
    }
}
