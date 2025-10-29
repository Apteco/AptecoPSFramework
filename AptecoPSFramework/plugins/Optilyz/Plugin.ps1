function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "5a00250c-dfaa-4f7d-9859-f657489ff494"

        # general information about this plugin
        "name" = "Optilyz"
        "version" = "0.0.1"
        "lastUpdate" = "2025-11-29"
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
            "mailings" = $true
            "lists" = $true
            "preview" = $true
            "upload" = $true
            "broadcast" = $true
            "responses" = $true
        }
    }
}
