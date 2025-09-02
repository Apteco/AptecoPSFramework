function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "5fb4956c-a5b6-4d5d-bff0-f406bc4f3588"

        # general information about this plugin
        "name" = "Sendinblue"
        "version" = "0.0.1"
        "lastUpdate" = "2024-07-17"
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
