﻿[PSCustomObject]@{

    # General
    "providername" = "PSCleverReach"

    # API
    "base" = "https://rest.cleverreach.com/v3/"             # main url to use for cleverreach, could be changed for newer versions or using API gateways
    "contentType" = "application/json; charset=utf-8"       # content type string that is always used for API requests
    "pageSize" = 500                                        # if paging is used for the API requests, this is the default setting for a pagesize
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

        # Sometimes connections are getting closed, so adding the option to disable keepalive
        "DisableKeepAlive" = $true

    }

    # Token refreshment
    "token" = [PSCustomObject]@{

        # Email notifications
        "notificationReceiver" =  "admin@example.com"
        "sendMailOnSuccess" =  $false
        "sendMailOnCheck" =  $false
        "sendMailOnFailure" =  $false

        # Refreshing task
        "taskDefaultName" =  "Apteco CleverReach Token Refresher"
        "dailyTaskSchedule" =  6 # runs every day at 6 local time in the morning
        "refreshTtl" = 604800 # seconds; refresh one week before expiration

        # Process to use for refresh task
        "powershellExePath" = "powershell.exe" # e.g. use pwsh.exe for PowerShell7

        #"tokenfile" =  "C:\Test\cr.token"
        #"createTokenFile" = $true
        "tokenSettingsFile" = "" # Path for the settings file that contains important information about the token creation and refreshing

        # Not implemented yet, but settings for the token file
        "exportTokenToFile" = $true                         # only used, if the token usage is on 'generate'
        "tokenUsage" = "consume"                            # consume|generate -> please have only one setting where you generate the token
        "encryptTokenFile" = $false                         # only used, if the token usage is on 'generate', when 'consume' then the tokenfile will be decrypted
                                                            # be careful, that the encryption is user dependent so cannot be shared between multiple users
        "tokenFilePath" = ""                                # path for the file containing the token that should be consumed or generated



    }

    # API Authentication
    "login" = [PSCustomObject]@{
        "refreshTtl" = 604800                               # 7 days in seconds
        "refreshtoken" = ""
        "accesstoken" = ""
        "refreshTokenAutomatically" = $true
    }

    # Upload settings
    "upload" = [PSCustomObject]@{
        "reservedFields" = [Array]@(,"tags")                # If one of these fields are used, the whole process will pause
        "countRowsInputFile" = $true
        "validateReceivers" = $true
        "excludeNotValidReceivers" = $false                 # !!! IMPORTANT SETTING $false allows new records to be uploaded to CleverReach, $true means only activated receivers in CleverReach on that list will be updated and tagged
        "excludeBounces" = $true
        "excludeGlobalDeactivated" = $false                 # Excludes receivers, that are deactivated on any list. So if there is a receiver active on any list, but active on the currently used list, it will be excluded, if this setting is $true
        "excludeLocalDeactivated" = $true
        "uploadSize" = 300                                  # Max no of rows per batch upload call, max of 1000
        "tagSource" = "Apteco"                              # Prefix of the tag, that will be used automatically, when doing mailings (not tagging)
        "useTagForUploadOnly" = $true
        "loadRuntimeStatistics" = $true                     # Loads total, active, inactive, bounced receivers of the group after upserting the data. This loads all receivers on the list, so can need a while and cause many api calls
        "nullAttributeWhenValue" = @(                       # keywords that should be replace with an empty string for CleverReach
            ""
            "null"
            "ContentObject"
            "-"
        )
    }

    # Broadcast settings
    "broadcast" = [PSCustomObject]@{

        # Settings for the copy of the mailing
        "defaultContentType" = "html/text"                  # "html", "text" or "html/text"
        "defaultEditor" = "eddytor"                         # "eddytor", "wizard", "freeform", "advanced", "plaintext"
        "defaultOpenTracking" = $true
        "defaultClickTracking" = $true
        "defaultLinkTrackingUrl" = "" # "link_tracking_url": "27.wayne.cleverreach.com",
        "defaultLinkTrackingType" = "" # "link_tracking_type": "google",  // "google", "intelliad", "crconnect"
        "defaultGoogleCampaignName" = "" # "google_campaign_name": "My Campaign",  // in case of link_tracking_type == "google"

        # TODO The google campaign name may need to be more flexible in future

        # Preheader options
        "preheaderFieldname" = "AptecoPreheader"
        "addPreheaderAfterBody" = $true
        "removeNativePreheader" = $true                     # If a custom header gets added, you can also set this option to remove the native CR preheader

        # Release/sending
        "defaultReleaseOffset" = 120                        # Default amount of seconds that are added to the current unix timestamp to release the mailing
        "waitUntilFinished" = $false
        "maxWaitForFinishedAfterOffset" = 120           # Wait for another 120 seconds (or more or less) until it is confirmed of send off

    }

    "preview" = [PSCustomObject]@{
        "previewGroupName" = "Apteco_Preview"
    }

    "responses" = [PSCustomObject]@{

        "useSeparateLogfile" = $false
        "logfile" = "$( (resolve-path ".").path )\response.log"

        # TODO rename this column
        "urnFieldName" = "urn"                              # Primary key field name, which should be global and is needed for matching
        "communicationKeyAttributeName" = "communication_key"           # The local group attribute that will be loaded from the group, not used yet

        # File export settings
        "filePrefix" = "responses_"                         # Prefix for the response files that are generated

        # Periods to ask the API for
        "messagePeriod" = 60                                # How many days do you want to go backwards for loading mailing reports?
        "responsePeriod" = 180                              # How many days to you want to go backwards for response data per message? Normally this numbers is smaller than the messagePeriod

        # This mechanism can enhance the performance massively and will override "responsePeriod" as the last saved timestamp will be used as a start date
        "saveLastTimestamp" = $true                        # TODO set this to true later
        "saveLastTimestampFile" = "$( (resolve-path ".").path )\lastresponsedownload.json"

        # Decide, which responses should be donwloaded
        "loadSent" = $true
        "loadOpens" = $true
        "loadClicks" = $true
        "loadBounces" = $true
        "loadUnsubscribes" = $true
        #"loadBlocklistAsUnsubscribes" = $true

        # Settings for FERGE
        "triggerFerge" = $true
        "fergePath" = "$( $Env:ProgramFiles )\Apteco\FastStats Email Response Gatherer x64\EmailResponseGatherer64.exe"
        "fergeConfigurationXml" = "D:\Scripts\CleverReach\PSCleverReachModule\responses.xml"

    }

    # Create the binary value for loading the cleverreach details for each receiver
    "loadDetails" = @{
        "events" = $true
        "orders" = $false
        "tags" = $true
    }

}

