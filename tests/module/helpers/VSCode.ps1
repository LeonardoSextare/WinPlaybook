function New-ExtensaoAnsibleFalsa {
    <#
    .SYNOPSIS
    Cria uma pasta falsa da extensão Ansible do VS Code, com os trechos que o patch do WinPlaybook troca, e devolve o caminho dela.

    .DESCRIPTION
    A pasta se chama redhat.ansible-<versão>. Cada arquivo do language server que o patch
    da versão troca recebe os trechos originais, entre outros textos. Sem trechos, cria os
    arquivos sem eles, como numa versão que mudou o código. O módulo WinPlaybook precisa
    estar importado.

    .PARAMETER PastaDasExtensoes
    A pasta onde a extensão falsa é criada.

    .PARAMETER Versao
    A versão da extensão.

    .PARAMETER SemTrechos
    Cria os arquivos sem os trechos que o patch troca.

    .EXAMPLE
    $extensao = New-ExtensaoAnsibleFalsa -PastaDasExtensoes $TestDrive -Versao '26.11.0'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $PastaDasExtensoes,
        [Parameter(Mandatory)] [string] $Versao,
        [switch] $SemTrechos
    )

    $caminho = Join-Path $PastaDasExtensoes "redhat.ansible-$Versao"
    $trocas = InModuleScope WinPlaybook { (Get-PatchDaExtensaoAnsible)['26.11.0'] }
    foreach ($arquivo in @($trocas | ForEach-Object { $_.Arquivo } | Sort-Object -Unique)) {
        $trechos = @($trocas | Where-Object { $_.Arquivo -eq $arquivo } | ForEach-Object { $_.De })
        if ($SemTrechos) {
            $trechos = @('codigo de outra versao')
        }
        $caminhoDoArquivo = Join-Path $caminho "packages\ansible-language-server\dist\$arquivo"
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $caminhoDoArquivo) -Force
        [IO.File]::WriteAllText($caminhoDoArquivo, 'inicio;' + ($trechos -join ';meio;') + ';fim')
    }

    return $caminho
}

function Get-ExtensaoAnsibleDeTeste {
    <#
    .SYNOPSIS
    Baixa a extensão Ansible do VS Code da Open VSX, na versão escolhida, e devolve a pasta dela.

    .DESCRIPTION
    A extensão fica em %LOCALAPPDATA%\WinPlaybookTestes\vscode\redhat.ansible-<versão>, e as
    outras chamadas reaproveitam a pasta, sem internet. Os testes copiam a pasta antes de
    aplicar o patch, para não alterar a cópia guardada.

    .PARAMETER Versao
    A versão da extensão.

    .EXAMPLE
    $extensao = Get-ExtensaoAnsibleDeTeste -Versao '26.11.0'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Versao
    )

    $pasta = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) "WinPlaybookTestes\vscode\redhat.ansible-$Versao"
    $jaFoiBaixada = Test-Path -LiteralPath (Join-Path $pasta 'package.json') -PathType Leaf
    if (-not $jaFoiBaixada) {
        $pacote = Join-Path ([IO.Path]::GetTempPath()) "redhat.ansible-$Versao-$([guid]::NewGuid().ToString('N')).zip"
        $extraida = "$pacote.extraida"
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri "https://open-vsx.org/api/redhat/ansible/$Versao/file/redhat.ansible-$Versao.vsix" -OutFile $pacote -UseBasicParsing
            Expand-Archive -LiteralPath $pacote -DestinationPath $extraida
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $pasta) -Force
            Move-Item -LiteralPath (Join-Path $extraida 'extension') -Destination $pasta
        }
        finally {
            Remove-Item -LiteralPath $pacote, $extraida -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    return $pasta
}

function Invoke-ClienteLsp {
    <#
    .SYNOPSIS
    Roda o language server de uma pasta da extensão Ansible com o cliente LSP dos testes e devolve o que ele registrou.

    .DESCRIPTION
    O cliente (tests/module/data/vscode/cliente-lsp.js) abre o site.yml do projeto, espera a
    documentação dos módulos, pede o hover de ansible.builtin.debug e de
    community.general.ini_file e espera os diagnósticos do ansible-lint. Roda com o node do
    Path ou, sem ele, com o do VS Code (Code.exe com ELECTRON_RUN_AS_NODE). Os shims ficam no
    começo do Path, e o wsl.localhost é liberado como no security.allowedUNCHosts do VS Code.
    Devolve os registros do cliente, um objeto por linha.

    .PARAMETER PastaDaExtensao
    A pasta da extensão, com o language server em packages\ansible-language-server.

    .PARAMETER PastaDoProjeto
    A pasta do projeto, com o site.yml.

    .PARAMETER PastaDosShims
    A pasta dos shims do WinPlaybook.

    .EXAMPLE
    $registros = Invoke-ClienteLsp -PastaDaExtensao $extensao -PastaDoProjeto $projeto -PastaDosShims $pastaDosShims
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $PastaDaExtensao,
        [Parameter(Mandatory)] [string] $PastaDoProjeto,
        [Parameter(Mandatory)] [string] $PastaDosShims
    )

    $node = Get-Command -Name 'node' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $programa = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\Microsoft VS Code\Code.exe'
    if ($node) {
        $programa = $node.Source
    }
    $cliente = (Resolve-Path (Join-Path $PSScriptRoot '../data/vscode/cliente-lsp.js')).Path
    $servidor = Join-Path $PastaDaExtensao 'packages\ansible-language-server\dist\cli.cjs'
    $saida = (New-TemporaryFile).FullName
    $erros = (New-TemporaryFile).FullName
    $pathOriginal = $env:Path
    $env:Path = "$PastaDosShims;$env:Path"
    $env:NODE_UNC_HOST_ALLOWLIST = 'wsl.localhost'
    $env:ELECTRON_RUN_AS_NODE = '1'
    try {
        Start-Process -FilePath $programa -ArgumentList "`"$cliente`"", "`"$servidor`"", "`"$PastaDoProjeto`"" -RedirectStandardOutput $saida -RedirectStandardError $erros -NoNewWindow -Wait
        foreach ($linha in Get-Content -LiteralPath $saida -Encoding UTF8) {
            Write-Output (ConvertFrom-Json -InputObject $linha)
        }
    }
    finally {
        $env:Path = $pathOriginal
        Remove-Item -LiteralPath 'Env:NODE_UNC_HOST_ALLOWLIST', 'Env:ELECTRON_RUN_AS_NODE' -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $saida, $erros -ErrorAction SilentlyContinue
    }
}
