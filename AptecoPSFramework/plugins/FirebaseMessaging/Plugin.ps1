function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "092b2e03-0390-47ed-a30c-8c239cba146d"

        # general information about this plugin
        "name" = "Firebase Messaging"
        "version" = "0.0.1"
        "lastUpdate" = "2025-11-22"
        "category" = "channel"
        "type" = "mobile"
        "stage" = "dev"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @()
            "psPackages" = @()
        }

        # Supported functions
        "functions" = [PSCustomObject]@{
            "mailings" = $false
            "lists" = $false
            "preview" = $false
            "upload" = $true
            "broadcast" = $false
            "responses" = $false
        }
    }
}
