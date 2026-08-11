. "$PSScriptRoot\parts\config.ps1"
. "$PSScriptRoot\parts\ui.ps1"
. "$PSScriptRoot\parts\menus.ps1"
. "$PSScriptRoot\parts\flutter.ps1"

$project = ProjectConfig

$Host.UI.RawUI.WindowTitle = "Flutter Project Wizard"

$originalForegroundColor = $Host.UI.RawUI.ForegroundColor
$originalBackgroundColor = $Host.UI.RawUI.BackgroundColor

[Console]::TreatControlCAsInput = $true

Clear-Host

$flutterPath = Test-Flutter

if (-not $flutterPath) {
    Write-ErrorMsg "CRITICAL: Flutter SDK was not found in your system PATH."
    Write-Hint "Please install Flutter and ensure 'flutter/bin' is added to your Environment Variables."
    Clean-Exit 1
}

Write-Header "Flutter Project Wizard"
Write-Hint "Using Flutter executable found at: $flutterPath"

$project.Name = Read-ValidatedInput `
    -Prompt "Project Name (e.g., my_awesome_app)" `
    -Validator { param($v) $v -cmatch '^[a-z][a-z0-9_]*$' } `
    -ErrorMessage "Use lowercase letters, numbers, and underscores. The name must start with a letter." `
    -AllowEmpty $false

Write-Host ""
Write-Host "Output Directory (Optional, leave blank for current directory):" -ForegroundColor Yellow
$project.OutputDirectory = Read-Host ">"
if ($project.OutputDirectory) {
    $project.OutputDirectory = Convert-Path -Path $project.OutputDirectory -ErrorAction SilentlyContinue -DefaultValue $project.OutputDirectory
    if (-not (Test-Path $project.OutputDirectory)) {
        Write-Host "Target folder directory doesn't exist. Creating it now..." -ForegroundColor DarkGray
        $null = New-Item -ItemType Directory -Path $project.OutputDirectory -Force
    }
}

$project.Description = Read-ValidatedInput `
    -Prompt "Project Description (Optional)" `
    -Validator { $true } `
    -ErrorMessage ""

$project.Organization = Read-ValidatedInput `
    -Prompt "Organization ID (e.g., com.example, used for package and bundle identifiers) (Optional)" `
    -Validator {
        param($v)
        if ([string]::IsNullOrWhiteSpace($v)) { return $true }
        return ($v -match '^([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+$')
    } `
    -ErrorMessage "Use reverse-domain notation such as com.example or dev.mycompany."

$project.Template = Show-Menu "What type of Flutter project do you want to create?" @(
    "app",
    "module",
    "package",
    "package_ffi",
    "plugin",
    "skeleton"
)

$project.Empty = $false
if ($project.Template -eq "app") {
    $emptyChoice = Show-Menu "Create an Empty App Template? (Minimal main.dart with no sample comments or counters)" @("Yes","No")
    $project.Empty = ($emptyChoice -eq "Yes")
}

$project.AndroidLanguage = ""
if ($project.Template -eq "app" -or $project.Template -eq "plugin") {
    $project.AndroidLanguage = Show-Menu "Android Native Code Language (Kotlin recommended)" @("kotlin","java")
}

$project.Platforms = @()
if ($project.Template -eq "app" -or $project.Template -eq "plugin") {
    $project.Platforms = Show-CheckboxMenu `
        -Title "Select Target Platforms (folders will be generated for these platforms)" `
        -Items @("android","ios","web","windows","linux","macos") `
        -Selected @("android","ios","web","windows","linux","macos")
}

$advanced = Show-Menu "Configure Advanced Creation Options? (pub get, offline mode, overwrite)" @("No","Yes")

$project.RunPubGet = $true
$project.Offline = $false
$project.Overwrite = $false

if ($advanced -eq "Yes") {
    $project.RunPubGet = ((Show-Menu "Automatically run 'flutter pub get' after creation?" @("Yes","No")) -eq "Yes")
    $project.Offline = ((Show-Menu "Offline Mode? (Use cached packages only)" @("Yes","No")) -eq "Yes")
    $project.Overwrite = ((Show-Menu "Force overwrite if files already exist?" @("Yes","No")) -eq "Yes")
}

$cmdArgs = @("create")

$cmdArgs += @("--project-name", $project.Name)

if ($project.Description) {
    $cmdArgs += @("--description", $project.Description)
}

if ($project.Organization) {
    $cmdArgs += @("--org", $project.Organization)
}

if ($project.AndroidLanguage) {
    $cmdArgs += @("--android-language", $project.AndroidLanguage)
}

if ($project.Platforms.Count -gt 0) {
    $cmdArgs += @("--platforms", ($project.Platforms -join ","))
}

if ($project.Template) {
    $cmdArgs += @("--template", $project.Template)
}

if ($project.Empty) { $cmdArgs += "--empty" }
if (-not $project.RunPubGet) { $cmdArgs += "--no-pub" }
if ($project.Offline) { $cmdArgs += "--offline" }
if ($project.Overwrite) { $cmdArgs += "--overwrite" }

$targetPath = if ($project.OutputDirectory) {
    Join-Path $project.OutputDirectory $project.Name
} else {
    Join-Path $PWD.Path $project.Name
}

$cmdArgs += $targetPath

Clear-Host

Show-ProjectSummary `
    -Project $project `
    -TargetPath $targetPath `
    -CommandArguments $cmdArgs

Write-Host "Create this project? (Y/N):" -ForegroundColor Green
$confirm = Read-Host ">"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-ErrorMsg "Operation terminated by user request."
    Clean-Exit 0
}

Write-Success "`nInitializing Flutter project engine..."
& flutter $cmdArgs

if ($LASTEXITCODE -eq 0) {
    Write-Success "`nProject generated successfully at $targetPath"
    Clean-Exit 0
} else {
    Write-ErrorMsg "`nFlutter CLI returned a non-zero exit status code ($LASTEXITCODE). Check logs above."
    Clean-Exit $LASTEXITCODE
}