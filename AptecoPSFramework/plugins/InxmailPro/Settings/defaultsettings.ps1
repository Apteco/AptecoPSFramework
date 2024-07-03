[PSCustomObject]@{

    # General
    "providername" = "PSXPro"

    # API
    "base" = "https://api.inxmail.com/#ACCOUNT#/rest/v1"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/hal+json;charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 1000                                          # max pagesize = 1000, default 1000
    "additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod
    "logAPIrequests" = $true                                # log information like 'GET https://rest.cleverreach.com:443/v3/groups.json/1158984/stats'

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
        #"account" = ""
        "username" = ""
        "password" = ""
    }

    # Upload settings
    "upload" = [PSCustomObject]@{

        "countRowsInputFile" = $true
        "uploadSize" = 1000

        "createNewFields" = $true

        # New List settings
        "newList" = [PSCustomObject]@{
            "senderAddress" = "info@apteco.de"
            "type" = "STANDARD"
            "description" = "Dies ist eine automatisch erstellte Liste."
        }

        # fixed column names
        "emailColumnName" = "email"
        "permissionColumnName" = "trackingPermission"   # needs value "GRANTED"

        # permission defaults
        #"trackingPermissionConflictMode" = "OVERWRITE_FULL" # OVERWRITE_FULL|KEEP_EXISTING|OVERWRITE_FULL

        # Other settings
        # "importConflictMode" = "OVERWRITE_FULL" # OVERWRITE_FULL|KEEP_EXISTING|OVERWRITE_FULL|UPDATE
        #truncate
        #resubscribe

    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{
        "sendMailing" = $true
    }

    "preview" = [PSCustomObject]@{
    }

    "responses" = [PSCustomObject]@{

    }

}

