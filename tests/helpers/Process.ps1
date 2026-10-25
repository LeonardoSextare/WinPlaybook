function Invoke-CommandLine([string] $FilePath, [string] $ArgumentList) {
    $outputFilePath = (New-TemporaryFile).FullName
    $errorFilePath = (New-TemporaryFile).FullName
    try {
        $parameters = @{
            FilePath               = $FilePath
            NoNewWindow            = $true
            Wait                   = $true
            PassThru               = $true
            RedirectStandardOutput = $outputFilePath
            RedirectStandardError  = $errorFilePath
        }
        if ($ArgumentList) {
            $parameters.ArgumentList = $ArgumentList
        }

        $process = Start-Process @parameters

        [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output   = "$(Get-Content -LiteralPath $outputFilePath -Raw)".Trim()
            Error    = "$(Get-Content -LiteralPath $errorFilePath -Raw)".Trim()
        }
    }
    finally {
        Remove-Item -LiteralPath $outputFilePath, $errorFilePath -ErrorAction SilentlyContinue
    }
}
