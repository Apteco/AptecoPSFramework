[PSCustomObject]@{

    # General
    "providername" = "PSBrevo"

    # API
    "base" = "https://api.newsletter2go.com/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
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
        "user" = "<user>"
        "password" = "<password>"
        "authkey" = "<apikey>"                               # auth key from Sendinblue
    }

    "token" = [PSCustomObject]@{
        #"encryptTokenFile" = $false                         # be careful, that the encryption is user dependent so cannot be shared between multiple users
        "tokenFilePath" = ".\sib.token"                     # path for the file containing the token that should be consumed or generated
        #"encryptTokenInSettings" = $false
        "tokenSettingsFile" = ".\sib_token.json"            # Path for the settings file that contains important information about the token creation and refreshing
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

