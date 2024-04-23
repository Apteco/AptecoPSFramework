function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "bfd1421f-bfac-4a59-8067-4a4730737061"

        # general information about this plugin
        "name" = "emarsys"
        "version" = "0.0.1"
        "lastUpdate" = "2024-02-26"
        "category" = "channel"
        "type" = "email"
        "stage" = "dev"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @(
                #"PSOAuth"       # TODO make sure this module is loaded
                "ConvertStrings"
                "ConvertUnixTimestamp"
                #"EncryptCredential"
                #"SqlServer"
                "MeasureRows"
                #"SimplySQL"
                #"TestCredential"
                #"MergePSCustomObject"
            )
            "psPackages" = @(
            )
        }

        # Supported functions
        "functions" = [PSCustomObject]@{
            "mailings" = $true
            "lists" = $true
            "preview" = $true
            "upload" = $true
            "broadcast" = $true
            "responses" = $false
        }

    }
}
