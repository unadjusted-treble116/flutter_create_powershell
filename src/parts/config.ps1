function ProjectConfig {
    return [PSCustomObject]@{
        Name            = ""
        OutputDirectory = ""
        Description     = ""
        Organization    = ""
        Template        = ""
        Empty           = $false
        Platforms       = @()
        AndroidLanguage = ""

        # Advanced options
        RunPubGet       = $true
        Offline         = $false
        Overwrite       = $false
    }
}