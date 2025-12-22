function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "52ccae94-7f10-435b-89a1-3e0604545a27"

        # general information about this plugin
        "name" = "Apteco Cloud"
        "version" = "0.0.1"
        "lastUpdate" = "2025-12-22"
        "category" = "data"
        "type" = "transfer"
        "stage" = "dev"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @(
                "SQLPS"
                "ConvertStrings"
                "awspowershell"
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
