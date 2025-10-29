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
        "token" = "" # Optilyz API Token
    }

    # Upload settings
    "upload" = [PSCustomObject]@{

        "automationStates" = [Array]@("paused","live") # paused|live
        "rowsPerUpload" = 800
        "timeout" = 30 # seconds

    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

    }

    "preview" = [PSCustomObject]@{
    }

    "responses" = [PSCustomObject]@{

    }

}

