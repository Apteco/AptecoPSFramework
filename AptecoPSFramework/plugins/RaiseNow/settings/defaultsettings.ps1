[PSCustomObject]@{

    # General
    "providername" = "PSRaiseNow"

    # API
    "base" = "https://api.raisenow.io/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json; charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 500                                        # if paging is used for the API requests, this is the default setting for a pagesize
    "additionalHeaders" = [PSCustomObject]@{
        "Accept-Encoding" = "gzip"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod
    "logAPIrequests" = $true

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

    # Token refreshment
    "token" = [PSCustomObject]@{

        "tokenSettingsFile" = ".\token.json" # Path for the settings file that contains important information about the token creation and refreshing
        "encryptTokenFile" = $true                         # only used, if the token usage is on 'generate', when 'consume' then the tokenfile will be decrypted
                                                            # be careful, that the encryption is user dependent so cannot be shared between multiple users
    }

    # API Authentication
    "login" = [PSCustomObject]@{
        "clientId" = ""
        "clientSecret" = ""
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{
    }

    "preview" = [PSCustomObject]@{
    }

    "responses" = [PSCustomObject]@{
    }

}

