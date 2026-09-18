param (
    [string]$Username = "murkurie",
    [string]$RepoName = "ELLX-Kernel"
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Setting up remote origin to: https://github.com/$Username/$RepoName.git" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

git remote set-url origin "https://github.com/$Username/$RepoName.git"

Write-Host "`nPushing branch '7.2-sl7-13.8' and tag 'v7.2.0-sl7-13.8' to your GitHub fork..." -ForegroundColor Yellow
git push -u origin 7.2-sl7-13.8 --tags

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Pushed to https://github.com/$Username/$RepoName!" -ForegroundColor Green
    Write-Host "Native ARM64 GitHub Actions build has been automatically triggered." -ForegroundColor Green
    Write-Host "Monitor your build here:" -ForegroundColor Green
    Write-Host "https://github.com/$Username/$RepoName/actions`n" -ForegroundColor Cyan
} else {
    Write-Host "`n[NOTICE] If you have not created your fork yet on GitHub:" -ForegroundColor Yellow
    Write-Host "1. Open https://github.com/ProgrammerIn-wonderland/ELLX-Kernel/fork in your browser." -ForegroundColor Yellow
    Write-Host "2. Click 'Create fork'." -ForegroundColor Yellow
    Write-Host "3. Re-run this script: .\push-to-fork.ps1" -ForegroundColor Yellow
}
