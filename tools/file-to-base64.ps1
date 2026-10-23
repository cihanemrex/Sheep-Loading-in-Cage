param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
$resolved = (Resolve-Path -LiteralPath $Path).Path
$encoded = [Convert]::ToBase64String([IO.File]::ReadAllBytes($resolved))
Set-Clipboard -Value $encoded
Write-Host 'Base64 copied to clipboard. Paste only into the matching GitHub Actions Secret.'
