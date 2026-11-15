Set-StrictMode -Version 3.0

foreach ($pasta in 'Private', 'Public') {
    foreach ($arquivo in Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath $pasta) -Filter '*.ps1' -Recurse) {
        . $arquivo.FullName
    }
}
