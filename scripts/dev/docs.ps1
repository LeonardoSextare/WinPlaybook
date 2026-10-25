#Requires -Version 7.4

# Builds the documentation in both languages and serves the full site as GitHub
# Pages publishes it, with the language selector and the root redirect.
# There is no hot reload: to write pages, use zensical serve, one language at a time.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ============================ Settings ============================
$DOCS_FOLDER = (Resolve-Path (Join-Path $PSScriptRoot '..\..\docs')).Path
$SITE_FOLDER = Join-Path $DOCS_FOLDER 'site'
$ROOT_PAGE_PATH = Join-Path $DOCS_FOLDER 'index.html'
$CONFIG_FILES = @('zensical.en.toml', 'zensical.pt-br.toml')

# The site lives under /WinPlaybook/ on GitHub Pages, so the local server uses the same path.
# Port 8080, so zensical serve (port 8000) can run at the same time.
$BASE_PATH = '/WinPlaybook/'
$SERVER_URL = 'http://localhost:8080'

$CONTENT_TYPES = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'text/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.xml'  = 'application/xml; charset=utf-8'
    '.svg'  = 'image/svg+xml'
    '.png'  = 'image/png'
    '.ico'  = 'image/x-icon'
}

# ============================ Functions ============================
function Build-Site {
    if (Test-Path $SITE_FOLDER) {
        Remove-Item $SITE_FOLDER -Recurse -Force
    }

    foreach ($configFile in $CONFIG_FILES) {
        uvx zensical build --config-file (Join-Path $DOCS_FOLDER $configFile) | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "The build of $configFile failed."
        }
    }

    # The root page is not part of either build: it sends visitors to their language.
    Copy-Item $ROOT_PAGE_PATH -Destination $SITE_FOLDER
}

# Returns the file in the site folder for a URL path under $BASE_PATH, or $null if there is none.
function Get-SiteFilePath([string] $UrlPath) {
    $relativePath = [Uri]::UnescapeDataString($UrlPath.Substring($BASE_PATH.Length))
    $filePath = [IO.Path]::GetFullPath((Join-Path $SITE_FOLDER $relativePath))

    $isInsideSite = $filePath.StartsWith($SITE_FOLDER, [StringComparison]::OrdinalIgnoreCase)
    if (-not $isInsideSite) {
        return $null
    }

    # Pages are folders with an index.html, like guides/vscode/.
    if (Test-Path $filePath -PathType Container) {
        $filePath = Join-Path $filePath 'index.html'
    }

    if (Test-Path $filePath -PathType Leaf) {
        return $filePath
    }
    $null
}

function Send-Response($Response, [int] $StatusCode, [byte[]] $Body, [string] $ContentType) {
    $Response.StatusCode = $StatusCode
    $Response.ContentType = $ContentType
    $Response.ContentLength64 = $Body.Length
    $Response.OutputStream.Write($Body, 0, $Body.Length)
    $Response.Close()
}

function Send-Redirect($Response, [string] $Location) {
    $Response.StatusCode = 301
    $Response.RedirectLocation = $Location
    $Response.Close()
}

function Send-SiteFile($Context) {
    $urlPath = $Context.Request.Url.AbsolutePath
    $response = $Context.Response

    if (-not $urlPath.StartsWith($BASE_PATH)) {
        Send-Redirect $response $BASE_PATH
        return
    }

    # Same as GitHub Pages: a folder without the final slash redirects to it,
    # so the relative links of the page resolve from the right folder.
    $filePath = Get-SiteFilePath $urlPath
    $isFolderWithoutSlash = $filePath -and $filePath.EndsWith('index.html') -and -not $urlPath.EndsWith('/') -and -not $urlPath.EndsWith('.html')
    if ($isFolderWithoutSlash) {
        Send-Redirect $response "$urlPath/"
        return
    }

    if (-not $filePath) {
        $body = [Text.Encoding]::UTF8.GetBytes("Not found: $urlPath")
        Send-Response $response 404 $body 'text/plain; charset=utf-8'
        return
    }

    $extension = [IO.Path]::GetExtension($filePath)
    $contentType = $CONTENT_TYPES[$extension] ?? 'application/octet-stream'
    Send-Response $response 200 ([IO.File]::ReadAllBytes($filePath)) $contentType
}

function Start-SiteServer {
    $listener = [Net.HttpListener]::new()
    $listener.Prefixes.Add("$SERVER_URL/")
    $listener.Start()

    $siteUrl = "$SERVER_URL$BASE_PATH"
    Write-Host "`nServing the site at $siteUrl" -ForegroundColor Green
    Write-Host 'Press Ctrl+C to stop.'
    Start-Process $siteUrl

    try {
        while ($listener.IsListening) {
            # Waits in short steps instead of blocking on GetContext(), so Ctrl+C can stop the loop.
            $contextTask = $listener.GetContextAsync()
            while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) { }
            Send-SiteFile $contextTask.GetAwaiter().GetResult()
        }
    }
    finally {
        $listener.Stop()
    }
}

# ============================ Execution ============================
Write-Host (('=' * 60) + "`n" + (' ' * 18) + 'WinPlaybook documentation' + "`n" + ('=' * 60)) -ForegroundColor DarkYellow

Write-Host '[1/2]' -ForegroundColor DarkCyan -NoNewline
Write-Host ' Building the site in both languages...'
Build-Site

Write-Host '[2/2]' -ForegroundColor DarkCyan -NoNewline
Write-Host ' Starting the server...'
Start-SiteServer
