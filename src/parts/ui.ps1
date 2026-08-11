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