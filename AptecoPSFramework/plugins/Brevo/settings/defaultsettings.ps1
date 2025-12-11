[PSCustomObject]@{

    # General
    "providername" = "PSBrevo"

    # API
    "base" = "https://api.brevo.com/v3/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json; charset=utf-8"       # content type string that is always used for API requests
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
        "defaultListFolderName" = "Apteco"                            # default folder to use for lists, 0 = global
        "sniffparameter" = "sample_size=1000, delim='\t'"     # duckdb parameter for reading the input csv file, e.g. you could define a date input format or the decimal point character
        "countRowsInputFile" = $True                          # Count rows of input file -> not needed
        "reservedFields" = [Array]@("fasdfis")                # If one of these fields are used, the whole process will pause
        "addNewAttributes" = $true                       # if attributes are found in the data that are not yet in Brevo, add them
        "urnFieldName" = "Urn"                               # field name in the input file that contains the URN (e.g. ID, partnerid,...)
        "DisableNotification" = $True                      # Disable notification email on import
        "EmptyContactsAttributes" = $False                  # Empty attributes that are used, but not filled in the import file
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

        # Release/sending
        "autoLaunch" = $false                              # Automatically launch the campaign after successful upload
        "defaultReleaseOffset" = 300                        # Default amount of seconds that are added to the current unix timestamp to release the mailing
        "waitUntilFinished" = $true                     # Wait until the mail is sent out
        "maxWaitForFinishedAfterOffset" = 240           # Wait for another 120 seconds (or more or less) until it is confirmed of send off

        "emailExpirationDate" = -1                             # Default amount of days until the email expires
        "defaultToField" = "{{DEFAULT_TO}}" #"{{contact.FNAME}} {{contact.LNAME}}"        # Default To field for the broadcast email, should be $null or "{{contact.FNAME}} {{contact.LNAME}}"
        "mirrorActive" = $True                              # Default setting for mirrorActive in the broadcast, this is the Online-Link that you can click to view the email in the browser
        "tag" = "Apteco"                                     # Default tag to use for the creation of the broadcast
        "defaultUpdateFormId" = $null                                  # Default update form id, if needed

        # Exclusions
        "exclusionListIds" = [Array]@()                           # List of Brevo list Ids to exclude from the broadcast
        "exclusionSegmentIds" = [Array]@()                        # List of Brevo segment Ids to exclude from the broadcast

    }

    "preview" = [PSCustomObject]@{

    }

    "responses" = [PSCustomObject]@{

    }

}

