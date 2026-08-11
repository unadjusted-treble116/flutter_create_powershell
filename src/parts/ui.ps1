function Clean-Exit {
    param([int]$ExitCode = 0)
    $Host.UI.RawUI.ForegroundColor = $originalForegroundColor
    $Host.UI.RawUI.BackgroundColor = $originalBackgroundColor
    Write-Host ""
    exit $ExitCode
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ("  " + $Text) -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-Hint { 
    param([string]$Text)
    Write-Host $Text -ForegroundColor DarkGray
}

function Write-ErrorMsg {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Red
}

function Write-Success {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Green
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

function Show-ProjectSummary {
    param(
        [PSCustomObject]$Project,
        [string]$TargetPath,
        [string[]]$CommandArguments
    )

    Write-Header "Project Summary"

    Write-Host "Project Name     : " -NoNewline
    Write-Host $Project.Name -ForegroundColor Green

    Write-Host "Target Path      : " -NoNewline
    Write-Host $TargetPath -ForegroundColor Green

    Write-Host "Description      : " -NoNewline
    Write-Host $(if ($Project.Description) { $Project.Description } else { "Default" }) -ForegroundColor Green

    Write-Host "Organization     : " -NoNewline
    Write-Host $(if ($Project.Organization) { $Project.Organization } else { "com.example" }) -ForegroundColor Green

    Write-Host "Template         : " -NoNewline
    Write-Host $Project.Template -ForegroundColor Green

    if ($Project.Platforms.Count -gt 0) {
        Write-Host "Platforms        : " -NoNewline
        Write-Host ($Project.Platforms -join ", ") -ForegroundColor Green
    }

    if ($Project.AndroidLanguage) {
        Write-Host "Android Language : " -NoNewline
        Write-Host $Project.AndroidLanguage -ForegroundColor Green
    }

    Write-Host "Run Pub Get      : " -NoNewline
    Write-Host $Project.RunPubGet -ForegroundColor Green

    Write-Host "Offline Mode     : " -NoNewline
    Write-Host $Project.Offline -ForegroundColor Green

    Write-Host "Overwrite        : " -NoNewline
    Write-Host $Project.Overwrite -ForegroundColor Green

    Write-Host ""
    Write-Host "Flutter Command Preview:" -ForegroundColor Cyan
    Write-Host "flutter $($CommandArguments -join ' ')" -ForegroundColor DarkGray

    Write-Host ""
}