Set-StrictMode -Version 3.0

foreach ($folder in 'Private', 'Public') {
    foreach ($file in Get-ChildItem -Path (Join-Path $PSScriptRoot $folder) -Filter '*.ps1' -Recurse) {
        . $file.FullName
    }
}
