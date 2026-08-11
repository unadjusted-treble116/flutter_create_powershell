# flutter_init.ps1

. "$PSScriptRoot\src\config.ps1"

$project = ProjectConfig

$Host.UI.RawUI.WindowTitle = "Flutter Project Wizard"

$originalForegroundColor = $Host.UI.RawUI.ForegroundColor
$originalBackgroundColor = $Host.UI.RawUI.BackgroundColor

function Clean-Exit {
    param([int]$ExitCode = 0)
    $Host.UI.RawUI.ForegroundColor = $originalForegroundColor
    $Host.UI.RawUI.BackgroundColor = $originalBackgroundColor
    Write-Host ""
    exit $ExitCode
}

$ui = [CurrentUserProvider]::new() 2>$null
[system.management.automation.runtime.eventsArgs] 2>$null
[Console]::TreatControlCAsInput = $true

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ("  " + $Text) -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-Hint { param([string]$Text) Write-Host $Text -ForegroundColor DarkGray }
function Write-ErrorMsg { param([string]$Text) Write-Host $Text -ForegroundColor Red }
function Write-Success { param([string]$Text) Write-Host $Text -ForegroundColor Green }

function Test-Flutter {
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    return $cmd.Source
}

function Read-ValidatedInput {
    param(
        [string]$Prompt,
        [scriptblock]$Validator,
        [string]$ErrorMessage,
        [bool]$AllowEmpty = $true
    )

    while ($true) {
        Write-Host ""
        Write-Host $Prompt -ForegroundColor Yellow
        $value = Read-Host ">"
        
        if ($value -eq "exit" -or $value -eq "quit") { Clean-Exit 0 }
        
        if ([string]::IsNullOrWhiteSpace($value)) {
            if ($AllowEmpty) { return "" }
        }

        if (& $Validator $value) {
            return $value
        }

        Write-ErrorMsg $ErrorMessage
    }
}

function Show-Menu {
    param(
        [string]$Title,
        [array]$Options
    )

    while ($true) {
        Write-Header $Title
        for ($i = 0; $i -lt $Options.Count; $i++) {
            Write-Host "[$($i+1)] $($Options[$i])" -ForegroundColor Yellow
        }

        Write-Host ""
        $choice = Read-Host "Choice"
        if ($choice -eq "exit") { Clean-Exit 0 }
        
        $num = 0
        if ([int]::TryParse($choice, [ref]$num)) {
            if ($num -ge 1 -and $num -le $Options.Count) {
                return $Options[$num-1]
            }
        }
        Write-ErrorMsg "Invalid selection."
    }
}

function Show-CheckboxMenu {
    param(
        [string]$Title,
        [string[]]$Items,
        [string[]]$Selected
    )

    $index = 0
    $startTop = [Console]::CursorTop
    
    Clear-Host
    Write-Header $Title
    Write-Hint "Use ↑ ↓ to move, SPACE to toggle, ENTER to confirm. (Ctrl+C to abort)"
    Write-Host ""
    
    $menuTop = [Console]::CursorTop

    while ($true) {
        [Console]::SetCursorPosition(0, $menuTop)
        
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $isSelected = $Selected -contains $Items[$i]
            $mark = if ($isSelected) { "●" } else { "○" }
            $color = if ($isSelected) { "Green" } else { "DarkGray" }

            if ($i -eq $index) {
                Write-Host "  > " -NoNewline -ForegroundColor Green
                Write-Host "$mark $($Items[$i])  " -ForegroundColor Green
            }
            else {
                Write-Host "    " -NoNewline
                Write-Host "$mark " -NoNewline -ForegroundColor $color
                Write-Host "$($Items[$i])  "
            }
        }

        $key = [Console]::ReadKey($true)

        if (($key.Modifiers -band [ConsoleModifiers]::Control) -and ($key.Key -eq [ConsoleKey]::C)) {
            Write-ErrorMsg "`nOperation aborted by user."
            Clean-Exit 1
        }

        switch ($key.Key) {
            "UpArrow" {
                if ($index -gt 0) { $index-- }
            }
            "DownArrow" {
                if ($index -lt ($Items.Count-1)) { $index++ }
            }
            "Spacebar" {
                if ($Selected -contains $Items[$index]) {
                    $Selected = $Selected | Where-Object { $_ -ne $Items[$index] }
                }
                else {
                    $Selected += $Items[$index]
                }
            }
            "Enter" {
                [Console]::SetCursorPosition(0, $menuTop + $Items.Count + 1)
                return $Selected
            }
        }
    }
}

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
    -Prompt "Project Name (lowercase, alphanumeric, and underscores only)" `
    -Validator { param($v) $v -match '^[a-z][a-z0-9_]*$' } `
    -ErrorMessage "Must be a valid Dart package name (e.g., my_awesome_app)." `
    -AllowEmpty $false

$project.OutputDirectory = Read-Host "Output Directory (Leave empty for current directory)"
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
    -Prompt "Organization Reverse Domain (e.g., com.example) (Optional)" `
    -Validator {
        param($v)
        if ([string]::IsNullOrWhiteSpace($v)) { return $true }
        return ($v -match '^([a-zA-Z0-9]+\.)+[a-zA-Z0-9]+$')
    } `
    -ErrorMessage "Invalid organization format. Use standard dot notation (e.g., dev.domain)."

$project.Template = Show-Menu "Select Template Type" @(
    "app",
    "module",
    "package",
    "package_ffi",
    "plugin",
    "skeleton"
)

$project.Empty = $false
if ($project.Template -eq "app") {
    $emptyChoice = Show-Menu "Create Empty Boilerplate App? (Removes comments & counters)" @("Yes","No")
    $project.Empty = ($emptyChoice -eq "Yes")
}

$project.AndroidLanguage = ""
if ($project.Template -eq "app" -or $project.Template -eq "plugin") {
    $project.AndroidLanguage = Show-Menu "Target Android Language" @("kotlin","java")
}

$project.Platforms = @()
if ($project.Template -eq "app" -or $project.Template -eq "plugin") {
    $project.Platforms = Show-CheckboxMenu `
        -Title "Target Platform Selection" `
        -Items @("android","ios","web","windows","linux","macos") `
        -Selected @("android","ios","web","windows","linux","macos")
}

$advanced = Show-Menu "Configure Advanced Flag Options?" @("No","Yes")

$project.RunPubGet = $true
$project.Offline = $false
$project.Overwrite = $false

if ($advanced -eq "Yes") {
    $project.RunPubGet = ((Show-Menu "Automatically run 'flutter pub get' after creation?" @("Yes","No")) -eq "Yes")
    $project.Offline = ((Show-Menu "Offline Mode? (Use cached packages only)" @("Yes","No")) -eq "Yes")
    $project.Overwrite = ((Show-Menu "Force overwrite if files already exist?" @("Yes","No")) -eq "Yes")
}

$cmdArgs = @("create")

$cmdArgs += @("--project-name", $projectName)

if ($description) {
    $cmdArgs += @("--description", $description)
}

if ($org) {
    $cmdArgs += @("--org", $org)
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

$targetPath = if ($outputDir) {
    Join-Path $outputDir $projectName
} else {
    Join-Path $PWD.Path $projectName
}

$cmdArgs += $targetPath

Clear-Host
Write-Header "Project Specification Summary"

Write-Host "Project Name     : " -NoNewline; Write-Host $projectName -ForegroundColor Green
Write-Host "Target Path      : " -NoNewline; Write-Host $targetPath -ForegroundColor Green
Write-Host "Template Type    : " -NoNewline; Write-Host $project.Template -ForegroundColor Green
if ($project.Platforms.Count -gt 0) {
    Write-Host "Platforms        : " -NoNewline; Write-Host ($project.Platforms -join ', ') -ForegroundColor Green
}
if ($org) {
    Write-Host "Organization     : " -NoNewline; Write-Host $org -ForegroundColor Green
}
Write-Host ""

Write-Host "Safe Generated Command Execution Blueprint:" -ForegroundColor Cyan
Write-Host "flutter $($cmdArgs -join ' ')" -ForegroundColor Yellow
Write-Host ""

Write-Host "Type YES to execute and initialize workspace:" -ForegroundColor Red
$confirm = Read-Host ">"

if ($confirm -ne "YES") {
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