#Requires -Version 7.4

<#
.SYNOPSIS
Gera a documentação nos dois idiomas e serve o site completo como o GitHub Pages publica.

.DESCRIPTION
O site completo tem o seletor de idioma e o redirecionamento da raiz, em
http://localhost:8080/WinPlaybook/. Não há hot reload: para escrever páginas, use o
zensical serve, um idioma por vez. O zensical serve usa a porta 8000, então os dois podem
rodar ao mesmo tempo.

.EXAMPLE
./scripts/dev/docs.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$pastaDaDocumentacao = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\docs')).Path
$pastaDoSite = Join-Path $pastaDaDocumentacao 'site'
$caminhoDaPaginaRaiz = Join-Path $pastaDaDocumentacao 'index.html'
$arquivosDeConfiguracao = @('zensical.en.toml', 'zensical.pt-br.toml')
$caminhoBaseNoGitHubPages = '/WinPlaybook/'
$urlDoServidor = 'http://localhost:8080'

$tiposDeConteudo = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'text/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.xml'  = 'application/xml; charset=utf-8'
    '.svg'  = 'image/svg+xml'
    '.png'  = 'image/png'
    '.ico'  = 'image/x-icon'
}

function Build-Site {
    <#
    .SYNOPSIS
    Gera o site nos dois idiomas e copia a página raiz, que manda o visitante para o idioma dele.

    .EXAMPLE
    Build-Site
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $siteJaExiste = Test-Path -LiteralPath $pastaDoSite
    if ($siteJaExiste) {
        Remove-Item -LiteralPath $pastaDoSite -Recurse -Force
    }

    foreach ($arquivoDeConfiguracao in $arquivosDeConfiguracao) {
        uvx zensical build --config-file (Join-Path $pastaDaDocumentacao $arquivoDeConfiguracao) | Out-Host
        $gerouOSite = $LASTEXITCODE -eq 0
        if (-not $gerouOSite) {
            throw "A geração do $arquivoDeConfiguracao falhou."
        }
    }

    Copy-Item -LiteralPath $caminhoDaPaginaRaiz -Destination $pastaDoSite
}

function Get-ArquivoDoSite {
    <#
    .SYNOPSIS
    Devolve o arquivo da pasta do site para um caminho de URL dentro do caminho base, ou $null quando ele não existe.

    .DESCRIPTION
    Uma pasta devolve o index.html dela, como guides/vscode/. Um caminho que sai da pasta
    do site devolve $null.

    .PARAMETER CaminhoDaUrl
    O caminho da URL pedida, como /WinPlaybook/pt-br/.

    .EXAMPLE
    Get-ArquivoDoSite -CaminhoDaUrl '/WinPlaybook/pt-br/'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $CaminhoDaUrl
    )

    $caminhoRelativo = [Uri]::UnescapeDataString($CaminhoDaUrl.Substring($caminhoBaseNoGitHubPages.Length))
    $caminhoDoArquivo = [IO.Path]::GetFullPath((Join-Path $pastaDoSite $caminhoRelativo))

    $estaDentroDoSite = $caminhoDoArquivo.StartsWith($pastaDoSite, [StringComparison]::OrdinalIgnoreCase)
    if (-not $estaDentroDoSite) {
        return $null
    }

    $ehPasta = Test-Path -LiteralPath $caminhoDoArquivo -PathType Container
    if ($ehPasta) {
        $caminhoDoArquivo = Join-Path $caminhoDoArquivo 'index.html'
    }

    $arquivoExiste = Test-Path -LiteralPath $caminhoDoArquivo -PathType Leaf
    if ($arquivoExiste) {
        return $caminhoDoArquivo
    }

    return $null
}

function Send-Resposta {
    <#
    .SYNOPSIS
    Envia uma resposta com um código de status, um corpo e um tipo de conteúdo, e fecha a resposta.

    .PARAMETER Resposta
    A resposta do HttpListener.

    .PARAMETER CodigoDeStatus
    O código de status HTTP, como 200 ou 404.

    .PARAMETER Corpo
    Os bytes do corpo.

    .PARAMETER TipoDeConteudo
    O Content-Type da resposta.

    .EXAMPLE
    Send-Resposta -Resposta $resposta -CodigoDeStatus 404 -Corpo $corpo -TipoDeConteudo 'text/plain; charset=utf-8'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [Net.HttpListenerResponse] $Resposta,
        [Parameter(Mandatory)] [int] $CodigoDeStatus,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [byte[]] $Corpo,
        [Parameter(Mandatory)] [string] $TipoDeConteudo
    )

    $Resposta.StatusCode = $CodigoDeStatus
    $Resposta.ContentType = $TipoDeConteudo
    $Resposta.ContentLength64 = $Corpo.Length
    $Resposta.OutputStream.Write($Corpo, 0, $Corpo.Length)
    $Resposta.Close()
}

function Send-Redirecionamento {
    <#
    .SYNOPSIS
    Redireciona permanentemente (301) para outro endereço e fecha a resposta.

    .PARAMETER Resposta
    A resposta do HttpListener.

    .PARAMETER Destino
    O endereço para onde o navegador vai.

    .EXAMPLE
    Send-Redirecionamento -Resposta $resposta -Destino '/WinPlaybook/'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [Net.HttpListenerResponse] $Resposta,
        [Parameter(Mandatory)] [string] $Destino
    )

    $Resposta.StatusCode = 301
    $Resposta.RedirectLocation = $Destino
    $Resposta.Close()
}

function Send-ArquivoDoSite {
    <#
    .SYNOPSIS
    Responde a uma requisição com o arquivo do site que ela pede.

    .DESCRIPTION
    Como o GitHub Pages, redireciona um endereço fora do caminho base para o caminho base,
    e uma pasta sem a barra final para o endereço com a barra, para os links relativos da
    página funcionarem. Um arquivo que não existe recebe 404.

    .PARAMETER Contexto
    O contexto da requisição, do HttpListener.

    .EXAMPLE
    Send-ArquivoDoSite -Contexto $contexto
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [Net.HttpListenerContext] $Contexto
    )

    $caminhoDaUrl = $Contexto.Request.Url.AbsolutePath
    $resposta = $Contexto.Response

    $estaNoCaminhoBase = $caminhoDaUrl.StartsWith($caminhoBaseNoGitHubPages, [StringComparison]::Ordinal)
    if (-not $estaNoCaminhoBase) {
        Send-Redirecionamento -Resposta $resposta -Destino $caminhoBaseNoGitHubPages
        return
    }

    $caminhoDoArquivo = Get-ArquivoDoSite -CaminhoDaUrl $caminhoDaUrl
    $ehPastaSemBarraFinal = $caminhoDoArquivo -and $caminhoDoArquivo.EndsWith('index.html') -and -not $caminhoDaUrl.EndsWith('/') -and -not $caminhoDaUrl.EndsWith('.html')
    if ($ehPastaSemBarraFinal) {
        Send-Redirecionamento -Resposta $resposta -Destino "$caminhoDaUrl/"
        return
    }

    if (-not $caminhoDoArquivo) {
        $corpo = [Text.Encoding]::UTF8.GetBytes("Não encontrado: $caminhoDaUrl")
        Send-Resposta -Resposta $resposta -CodigoDeStatus 404 -Corpo $corpo -TipoDeConteudo 'text/plain; charset=utf-8'
        return
    }

    $extensao = [IO.Path]::GetExtension($caminhoDoArquivo)
    $tipoDeConteudo = $tiposDeConteudo[$extensao] ?? 'application/octet-stream'
    Send-Resposta -Resposta $resposta -CodigoDeStatus 200 -Corpo ([IO.File]::ReadAllBytes($caminhoDoArquivo)) -TipoDeConteudo $tipoDeConteudo
}

function Start-ServidorDoSite {
    <#
    .SYNOPSIS
    Serve a pasta do site em http://localhost:8080/WinPlaybook/ e abre o navegador, até o Ctrl+C.

    .EXAMPLE
    Start-ServidorDoSite
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $ouvinte = [Net.HttpListener]::new()
    $ouvinte.Prefixes.Add("$urlDoServidor/")
    $ouvinte.Start()

    $urlDoSite = "$urlDoServidor$caminhoBaseNoGitHubPages"
    Write-Host "`nSite servido em $urlDoSite" -ForegroundColor Green
    Write-Host 'Aperte Ctrl+C para parar.'
    Start-Process -FilePath $urlDoSite

    $intervaloParaOCtrlCEmMilissegundos = 200
    try {
        while ($ouvinte.IsListening) {
            $tarefaDaRequisicao = $ouvinte.GetContextAsync()
            while (-not $tarefaDaRequisicao.AsyncWaitHandle.WaitOne($intervaloParaOCtrlCEmMilissegundos)) { }
            Send-ArquivoDoSite -Contexto $tarefaDaRequisicao.GetAwaiter().GetResult()
        }
    }
    finally {
        $ouvinte.Stop()
    }
}

Write-Host (('=' * 60) + "`n" + (' ' * 16) + 'Documentação do WinPlaybook' + "`n" + ('=' * 60)) -ForegroundColor DarkYellow

Write-Host '[1/2]' -ForegroundColor DarkCyan -NoNewline
Write-Host ' Gerando o site nos dois idiomas...'
Build-Site

Write-Host '[2/2]' -ForegroundColor DarkCyan -NoNewline
Write-Host ' Iniciando o servidor...'
Start-ServidorDoSite
