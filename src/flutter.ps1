$flutterPath = Test-Flutter
if (-not $flutterPath) {
    Write-ErrorMsg "CRITICAL: Flutter SDK was not found in your system PATH."
    Write-Hint "Please install Flutter and ensure 'flutter/bin' is added to your Environment Variables."
    Clean-Exit 1
}