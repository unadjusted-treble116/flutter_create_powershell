function Test-Flutter {
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue

    if (-not $cmd) {
        return $null
    }

    return $cmd.Source
}