function Invoke-CommandLine([string] $FilePath, [string] $ArgumentList) {
    $outputFilePath = (New-TemporaryFile).FullName
    try {
        $parameters = @{
            FilePath               = $FilePath
            NoNewWindow            = $true
            Wait                   = $true
            PassThru               = $true
            RedirectStandardOutput = $outputFilePath
        }
        if ($ArgumentList) {
            $parameters.ArgumentList = $ArgumentList
        }

        $process = Start-Process @parameters

        [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output   = "$(Get-Content -LiteralPath $outputFilePath -Raw)".Trim()
        }
    }
    finally {
        Remove-Item -LiteralPath $outputFilePath -ErrorAction SilentlyContinue
    }
}
