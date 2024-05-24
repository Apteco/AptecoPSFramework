[PSCustomObject]@{

    # General
    "providername" = "PSActiveCampaign"

    # API
    "base" = "https://dummy.api-us1.com/api/3/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json; charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 100                                        # default 20, max 100; if paging is used for the API requests, this is the default setting for a pagesize
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
        "apikey" = ""
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
        
        "createNewContacts" = $true
        "createNewFields" = $true
        "defaultList" = 123

    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

        "triggerMailing" = $false

    }

    "preview" = [PSCustomObject]@{
    }

    "responses" = [PSCustomObject]@{

    }

}

