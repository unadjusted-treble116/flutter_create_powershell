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