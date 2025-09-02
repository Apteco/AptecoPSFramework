[PSCustomObject]@{

    # General
    "providername" = "PSBrevo"

    # API
    "base" = "https://api.brevo.com/v3/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json"       # content type string that is always used for API requests
    "pageSize" = 10                                        # if paging is used for the API requests, this is the default setting for a pagesize
    "mailingLimit" = 999
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
        "RepeatOnHttpErrors" = [Array]@(502)
        "MaximumRetriesOnHttpErrorList" = 3

        # Generic errors like 404 that are not on the specific list
        "MaximumRetriesGeneric" = 1

    }

    # API Authentication
    "login" = [PSCustomObject]@{
        "apikey" = "<apikey>"                               # api key from Brevo
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
        defaultListFolder = 0                            # default folder to use for lists, 0 = global
        addNewAttributes = $true                       # if attributes are found in the data that are not yet in Brevo, add them
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

    }

    "preview" = [PSCustomObject]@{

    }

    "responses" = [PSCustomObject]@{

    }

}

