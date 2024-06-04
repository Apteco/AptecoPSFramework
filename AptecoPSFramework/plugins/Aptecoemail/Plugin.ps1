function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "f7e37624-3609-4fff-a6b1-57a5bb9d1959"

        # general information about this plugin
        "name" = "Apteco email"
        "version" = "0.0.1"
        "lastUpdate" = "2024-06-03"
        "category" = "channel"
        "type" = "email"
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
            "upload" = $false
            "broadcast" = $false
            "responses" = $true
        }

    }
}
