<#
.SYNOPSIS
    Rebuild the scouting page from the analysis repo and publish it to GitHub Pages.

.DESCRIPTION
    index.html here is a build artifact. This regenerates it with site.py, copies it
    in, and pushes if it actually changed. It does not re-run the crawl, the arbiter
    or the per-team fits - see the analysis repo's README for that.

.EXAMPLE
    .\publish.ps1
    .\publish.ps1 -SkipBuild
    .\publish.ps1 -Analysis D:\src\Aoe2Planner\analysis
#>
[CmdletBinding()]
param(
    [string]$Analysis = 'C:\Repos\Aoe2Planner\001\analysis',
    [string]$Python = 'C:\Python314\python.exe',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$page = Join-Path $Analysis 'index.html'

if (-not $SkipBuild) {
    $tools = Join-Path $Analysis 'tools'
    if (-not (Test-Path $tools)) { throw "No analysis tools at $tools - pass -Analysis" }
    Write-Host 'Rebuilding index.html...' -ForegroundColor Cyan
    Push-Location $tools
    try {
        $env:PYTHONIOENCODING = 'utf-8'
        & $Python site.py
        if ($LASTEXITCODE -ne 0) { throw "site.py failed ($LASTEXITCODE)" }
    } finally { Pop-Location }
}

if (-not (Test-Path $page)) { throw "No page at $page" }
Copy-Item $page .\index.html -Force

# a page whose numbers did not move is not worth a commit, and an empty commit would
# make the history look like the estimates changed when they did not
if (-not (git status --porcelain -- index.html)) {
    Write-Host 'Page unchanged - nothing to publish.' -ForegroundColor Yellow
    exit 0
}

$kb = [math]::Round((Get-Item .\index.html).Length / 1KB)
$stamp = Get-Date -Format 'yyyy-MM-dd'
git add index.html
git commit -m "Update scouting page ($stamp, $kb KB)"
git push

Write-Host "Published. Live in a minute at https://danielsery.github.io/aoe2-scout/" -ForegroundColor Green
