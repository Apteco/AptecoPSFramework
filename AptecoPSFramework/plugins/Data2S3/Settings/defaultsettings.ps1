[PSCustomObject]@{

    # General
    "providername" = "Data2S3"

    # API
    "additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod

    # Error handling
    "errorhandling" = [PSCustomObject]@{
    }

    # Token refreshment
    "token" = [PSCustomObject]@{    }

    # API Authentication
    "login" = [PSCustomObject]@{
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{
    }

    "preview" = [PSCustomObject]@{
    }

    "folderToCheck" = "C:\FastStats\Publish\DB01\system\Deliveries"
    "sqlserver" = [PSCustomObject]@{
        "instance" = "localhost"
        "database" = "WS_DB01"
        "username" = ""
        "password" = ""
    }
    "duckdb" = [PSCustomObject]@{
        "Path" = "C:\FastStats\Scripts\Data2S3\bin\duckdb.exe"
        "Database" = "C:\FastStats\Scripts\Data2S3\d2s.duckdb"
    }
    "S3" = [PSCustomObject]@{
        "BucketName"    = ""
        "AccessKey"     = ""
        "SecretKey"     = ""
        "Region"        = "eu-central-1"
        "Meta" = [PSCustomObject]@{
            "UploadedBy" = "PowerShell"
            "Department" = "Apteco"
        }
    }

}

