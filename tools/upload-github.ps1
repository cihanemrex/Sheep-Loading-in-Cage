param([Parameter(Mandatory=$true)][string]$RepositoryUrl)
$ErrorActionPreference = 'Stop'
if ($RepositoryUrl -notmatch '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:\.git)?$') {
    throw 'Use an HTTPS GitHub repository URL without credentials.'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Install Git for Windows first.' }
if (Test-Path (Join-Path $projectRoot '.git')) { throw 'Repository already initialized. Use normal Git commands for subsequent updates.' }
Push-Location $projectRoot
try {
    git init -b main
    if ($LASTEXITCODE -ne 0) { throw 'git init failed.' }
    # Explicit paths prevent accidental uploads of other local files.
    git add .github ci tools SheepCrate SheepCrate.xcodeproj .gitignore README_TR.md GITHUB_SETUP_TR.md
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    git commit -m 'Add offline Sheep Crate iOS app and build workflows'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed. Configure git user.name and user.email if prompted.' }
    git remote add origin $RepositoryUrl
    if ($LASTEXITCODE -ne 0) { throw 'git remote failed.' }
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw 'Push failed. Check GitHub login and that the remote repository is empty.' }
} finally { Pop-Location }
