function Get-PatchDaExtensaoAnsible {
    <#
    .SYNOPSIS
    Devolve as trocas que fazem a extensão Ansible do VS Code funcionar no Windows, por versão testada da extensão.

    .DESCRIPTION
    Cada versão testada tem uma lista de trocas nos arquivos do language server da extensão
    (packages\ansible-language-server\dist), com Arquivo, De e Para. As trocas fazem o
    language server rodar os comandos na pasta do Windows, e não na pasta da URI (/c:/...),
    encontrar o ansible-lint com o where, achar as collections do pacote ansible pela pasta
    do Ansible, sem o python3, e buscar a documentação dos módulos com barras normais.

    .EXAMPLE
    (Get-PatchDaExtensaoAnsible)['26.11.0']

    Devolve as trocas da versão 26.11.0.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $barrasNormais = 'e=e.split(String.fromCharCode(92)).join(`/`);'
    return @{
        '26.11.0' = @(
            @{ Arquivo = 'utils\commandRunner.cjs'; De = 'c=i||s,l=this.resolveConfigPath(s)'; Para = 'c=(i&&/^\/[A-Za-z]:/.test(i)?i.slice(1):i)||s,l=this.resolveConfigPath(s)' }
            @{ Arquivo = 'utils\commandRunner.cjs'; De = 'runCommand(`command`,`-v ${e}`)).stdout.trim()'; Para = 'runCommand(`where`,e)).stdout.trim().split(/\r?\n/)[0]' }
            @{ Arquivo = 'services\ansibleConfig.cjs'; De = 'let m=await c.runCommand(`python3`,` -c "import sys; print(sys.path, end=\\"\\")"`);this._collection_paths.push(...l(m.stdout))'; Para = 'this._collection_paths.push(i.dirname(this._ansible_location))' }
            @{ Arquivo = 'utils\docsFinder.cjs'; De = 'function s(e,t){if(!a.existsSync(e)'; Para = 'function s(e,t){' + $barrasNormais + 'if(!a.existsSync(e)' }
            @{ Arquivo = 'utils\docsFinder.cjs'; De = 'function c(e,t){let s=/* @__PURE__ */ new Map;'; Para = 'function c(e,t){' + $barrasNormais + 'let s=/* @__PURE__ */ new Map;' }
        )
    }
}
