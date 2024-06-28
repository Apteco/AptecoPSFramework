[PSCustomObject]@{

    # General
    "providername" = "PSemarsys"

    # API
    "base" = "https://api.emarsys.net/api/v2/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json;charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 500                                        # if paging is used for the API requests, this is the default setting for a pagesize
    #"mailingLimit" = 999
    #"additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    #}                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    #"additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    #}                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod
    #"logAPIrequests" = $true                                # log information like 'GET https://rest.cleverreach.com:443/v3/groups.json/1158984/stats'

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
        "username" = ""
        "secret" = ""
    }

    # Get messages options
    "messageOptions" = @(
        # [PSCustomObject]@{
        #         "id" = "add"
        #         "name" = "Add coupons"
        # }
        <#
        [PSCustomObject]@{
            "id" = "r"
            "name" = "remove"
        }
        #>
    )


    # Upload settings
    "upload" = [PSCustomObject]@{
        "countRowsInputFile" = $true
        "createNewFields" = $true
        "maximumThreads" = 100          # At emarsys it is more efficient to use multiple threads
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

    }

    "preview" = [PSCustomObject]@{
    }

    "responses" = [PSCustomObject]@{

    }

}

