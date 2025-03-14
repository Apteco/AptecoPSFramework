[PSCustomObject]@{

    # General
    "providername" = "PSSalesforceSalesCloud"

    # API
    "base" = "my.salesforce.com"             # will be combined with the account domain
    "apiversion" = "58.0"
    "instanceId" = "FS0" # This is the 3 to 6 character in a salesforce ID
    #"contentType" = "application/json; charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 500                                        # if paging is used for the API requests, this is the default setting for a pagesize
    #"mailingLimit" = 999
    "additionalHeaders" = [PSCustomObject]@{
        #"X-API" = "abcdef"
    }                                                       # static headers that should be send to the URL, sometimes needed for API gateways
    "additionalParameters" = [PSCustomObject]@{
        #"Proxy" = "http://proxy.example.com"
        #"SkipHeaderValidation" = $true
    }                                                       # additional parameter for the Invoke-RestMethod call like Proxy or ProxyCredential, see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod
    "logAPIrequests" = $true                                # log information like 'GET https://rest.cleverreach.com:443/v3/groups.json/1158984/stats'

    # Token refreshment
    "token" = [PSCustomObject]@{

        # Email notifications
        # "notificationReceiver" =  "admin@example.com"
        # "sendMailOnSuccess" =  $false
        # "sendMailOnCheck" =  $false
        # "sendMailOnFailure" =  $false

        # Refreshing task
        "taskDefaultName" =  "Apteco SalesforceSC Token Refresher"
        "dailyTaskSchedule" =  1 # runs every day at 6 local time in the morning
        "refreshTtl" = 604800 # seconds; refresh one week before expiration

        # Process to use for refresh task
        "powershellExePath" = "powershell.exe" # e.g. use pwsh.exe for PowerShell7

        #"tokenfile" =  "C:\Test\cr.token"
        #"createTokenFile" = $true
        "tokenSettingsFile" = "" # Path for the settings json file like c:\temp\sf_token_settings.json that contains important information about the token creation and refreshing

        # Not implemented yet, but settings for the token file
        "exportTokenToFile" = $true                         # only used, if the token usage is on 'generate'
        "tokenUsage" = "consume"                            # consume|generate -> please have only one setting where you generate the token
        "encryptTokenFile" = $false                         # only used, if the token usage is on 'generate', when 'consume' then the tokenfile will be decrypted
                                                            # be careful, that the encryption is user dependent so cannot be shared between multiple users
        "tokenFilePath" = ""                                # path for the file like C:\temp\sf.token containing the token that should be consumed or generated


    }

    # API Authentication
    "login" = [PSCustomObject]@{
        #"refreshTtl" = 604800                               # 7 days in seconds
        "refreshtoken" = ""
        "accesstoken" = ""
        "refreshTokenAutomatically" = $true
        "myDomain" = "aptecodach-dev-ed"
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
        
        "countRowsInputFile" = $true    # Count the rows

        "campaignFilter" = "IsDeleted = false and Status = 'Planned' and ParentId = null ORDER BY LastModifiedDate DESC"    # The filter to show campaigns in a dropdown
        
        "reservedFields" = [Array]@(,"Id")                # Those fields are removed on the upload

        "segmentVariablename" = ""                   # The segment variable name that is used to match against existing sub campaigns           
        "uploadIntoSubCampaigns" = $false                   # When you set this, you need a segment variable
        "leadExternalId" = ""                           # The external id for upsert into leads object
        "uploadSize" = 20000                            # The size for the uploads

        "checkSeconds" = 20
        "maximumWaitUntilJobFinished" = 3000                # 3000 seconds per default to wait for a job to finish
        "downloadFailedResults" = $True
        "errorThreshold" = 20                               # When we have n % errors of 100% records, throw an exception

    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

    }

    "preview" = [PSCustomObject]@{

    }

    "responses" = [PSCustomObject]@{

    }

}

