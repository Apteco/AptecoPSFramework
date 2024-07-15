function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "c2acbe04-8bc8-46bb-bb30-4c26947d328a"

        # general information about this plugin
        "name" = "Brevo"
        "version" = "0.0.1"
        "lastUpdate" = "2024-07-15"
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
            "mailings" = $true
            "lists" = $true
            "preview" = $false
            "upload" = $false
            "broadcast" = $false
            "responses" = $false
        }

    }
}
