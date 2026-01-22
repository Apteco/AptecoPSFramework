function Get-CurrentPluginInfo {
    [PSCustomObject]@{

        # identifier for this plugin - please do not change or use this twice
        "guid" = "b2290429-3da7-49b6-9960-de083aa38a88"

        # general information about this plugin
        "name" = "Data2S3"
        "version" = "0.1.0"
        "lastUpdate" = "2026-01-22"
        "category" = "data"
        "type" = "transfer"
        "stage" = "test"

        # have a look at ./bin/dependencies if you need more information about how to define this
        "dependencies" = [PSCustomObject]@{
            "psScripts" = @()
            "psModules" = @(
                #"WriteLog"
                #"EncryptCredential"
                #"powershell-yaml"
                "SQLPS"
                #"ImportDependency"
                "ConvertStrings"
                "awspowershell"
                "MeasureRows"
            )
            "psPackages" = @()
        }

        # Supported functions
        "functions" = [PSCustomObject]@{
            "mailings" = $true
            "lists" = $false
            "preview" = $false
            "upload" = $true
            "broadcast" = $true
            "responses" = $false
        }

    }
}
