function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "5e1b7a62-40a5-4a5b-977c-ebb8a8aaf6b4"

        # general information about this plugin
        "name" = "Data2S3 Upload"
        "version" = "0.0.1"
        "lastUpdate" = "2025-12-02"
        "category" = "channel"
        "type" = "upload"
        "stage" = "dev"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @(
                # TODO add all modules
            )
            "psPackages" = @()
        }

        # Supported functions
        "functions" = [PSCustomObject]@{
            "mailings" = $false
            "lists" = $false
            "preview" = $false
            "upload" = $false
            "broadcast" = $false
            "responses" = $false
        }

    }
}
