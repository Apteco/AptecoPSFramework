[PSCustomObject]@{

    # General
    "providername" = "FCM"

    # API
    "base" = "https://fcm.googleapis.com/v1"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json"       # content type string that is always used for API requests

    "additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod
    "logAPIrequests" = $false                                # log information like 'GET https://rest.cleverreach.com:443/v3/groups.json/1158984/stats'

    # Error handling
    "errorhandling" = [PSCustomObject]@{

        # Delay, if a problem happens and will be repeated
        "HttpErrorDelay" = 200

        # Specific http errors and their settings
        "RepeatOnHttpErrors" = [Array]@(502,429)    # 429 rate limiting
        "MaximumRetriesOnHttpErrorList" = 3

        # Generic errors like 404 that are not on the specific list
        "MaximumRetriesGeneric" = 1

    }

    # API Authentication
    "login" = [PSCustomObject]@{
        "serviceAccountKeyPath " = ""    # Absolute path to service account key JSON file
        "projectId" = ""                  # Firebase project ID
    }

    # Upload settings
    "upload" = [PSCustomObject]@{

        "duckConnectionString" = "Data Source=:memory:"            # DuckDB in-memory database

        "maxNotificationsPerSecond" = 100      # Throttle limit, but currently experience was around 60 messages per second
        "checkEveryNotifications" = 200        # Check results for errors every X notifications

        "lockfile" = ""                     # Path to lockfile
        "maxLockfileAge" = 3                # Maximum age of lockfile in hours

        "exclusionFolder" = ""              # Folder containing exclusion files

        "urnFieldName" = "kuid"          # Name of the field containing the device URN/token
        "informTokens" = @(

            "12345"                   # Example customer id to always inform (e.g. test device

        )


    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

    }

    "preview" = [PSCustomObject]@{
    }

    "responses" = [PSCustomObject]@{

    }

}

