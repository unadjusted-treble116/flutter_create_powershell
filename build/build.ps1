$ErrorActionPreference = "Stop"

$Root = Split-Path $PSScriptRoot -Parent
$Source = Join-Path $Root "src"
$Parts = Join-Path $Source "parts"
$Dist = Join-Path $Root "dist"

$OutputFile = Join-Path $Dist "flutter_create.ps1"

$Files = @(
    (Join-Path $Parts "config.ps1")
    (Join-Path $Parts "ui.ps1")
    (Join-Path $Parts "menus.ps1")
    (Join-Path $Parts "flutter.ps1")
    (Join-Path $Source "main.ps1")
)

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "Flutter Create - Build" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""

# Validate source files
foreach ($File in $Files) {
    if (-not (Test-Path $File -PathType Leaf)) {
        throw "Required source file not found: $File"
    }
}

# Recreate dist directory
if (Test-Path $Dist) {
    Remove-Item $Dist -Recurse -Force
}

New-Item -ItemType Directory -Path $Dist -Force | Out-Null

# Build output
$Output = @(
    "# Flutter Create PowerShell"
    ""
)

foreach ($File in $Files) {
    $RelativePath = $File.Substring($Root.Length + 1)

    Write-Host "Adding: $RelativePath" -ForegroundColor DarkGray

    $Output += ""
    $Output += "# ============================================================"
    $Output += "# $RelativePath"
    $Output += "# ============================================================"
    $Output += ""

    $Content = Get-Content -Path $File -Raw

    # main.ps1 loads the component files during development.
    # They are unnecessary in the final build, so we remove them. 
    if ($File -eq (Join-Path $Source "main.ps1")) {
        $Content = $Content -replace `
            '(?m)^\s*\.\s*"\$PSScriptRoot\\parts\\[^"]+"\s*\r?\n', ''
    }

    $Output += $Content
}

$Output |
    Set-Content -Path $OutputFile -Encoding utf8

Write-Host ""
Write-Host "Build completed successfully." -ForegroundColor Green
Write-Host "Output: $OutputFile" -ForegroundColor Green
Write-Host ""