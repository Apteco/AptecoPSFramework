function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "fb40f78e-861b-4393-9643-f697f2d90d44"

        # general information about this plugin
        "name" = "RaiseNow"
        "version" = "0.0.1"
        "lastUpdate" = "2024-09-17"
        "category" = "data"
        "type" = "crm"
        "stage" = "dev"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @(
                #"ConvertStrings"
                #"TestCredential"
            )
            "psPackages" = @()
        }
        "functions" = [PSCustomObject]@{
            "mailings" = $false
            "lists" = $false
            "preview" = $false
            "upload" = $false
            "broadcast" = $false
        }
    }
}
