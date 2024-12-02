function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "684af543-5282-4af9-a462-a665559d2b05"

        # general information about this plugin
        "name" = "FundraisingBox"
        "version" = "0.0.1"
        "lastUpdate" = "2024-12-02"
        "category" = "data"
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
            "mailings" = $False
            "lists" = $False
            "preview" = $False
            "upload" = $False
            "broadcast" = $False
            "responses" = $False
        }

    }
}
