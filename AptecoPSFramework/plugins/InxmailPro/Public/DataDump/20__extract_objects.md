```PowerShell

################################################
#
# INPUT
#
################################################

Param(
    [hashtable] $params
)

#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false

#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug ) {
    $params = [hashtable]@{
	    method = "first" # first|full|delta
    }
}


################################################
#
# NOTES
#
################################################

<#

https://apidocs.inxmail.com/xpro/rest/v1/

TODO [ ] implement paging


# Structure/Hierarchy of data

- Recipients (global list and attributes)
    |- Lists (recipients list dependent and lists data)
        |- Mailings
            |- Sendings
                |- Sendings protocol
                |- Bounces
                |- Clicks
                |- Web-Beacon-Hits (opens)
        |- Events/Subscriptions
        |- Events/Unsubscriptions
        |- Tracking Permissions
        |- Target Groups


#>

################################################
#
# SCRIPT ROOT
#
################################################

# if debug is on a local path by the person that is debugging will load
# else it will use the param (input) path
if ( $debug ) {
    # Load scriptpath
    if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
        $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    }
} else {
    $scriptPath = "$( $params.scriptPath )" 
}
Set-Location -Path $scriptPath


################################################
#
# SETTINGS
#
################################################

# General settings
$functionsSubfolder = "functions"
#$libSubfolder = "lib"
$settingsFilename = "settings.json"
$moduleName = "INXRESPONSES"
$processId = [guid]::NewGuid()

# Load settings
$settings = Get-Content -Path "$( $scriptPath )\$( $settingsFilename )" -Encoding UTF8 -Raw | ConvertFrom-Json

# Allow only newer security protocols
# hints: https://www.frankysweb.de/powershell-es-konnte-kein-geschuetzter-ssltls-kanal-erstellt-werden/
if ( $settings.changeTLS ) {
    $AllProtocols = @(    
        [System.Net.SecurityProtocolType]::Tls12
        #[System.Net.SecurityProtocolType]::Tls13,
        #,[System.Net.SecurityProtocolType]::Ssl3
    )
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
}

# more settings
$logfile = $settings.logfile
$lastSessionFile = $settings.sessionFile

# append a suffix, if in debug mode
if ( $debug ) {
    $logfile = "$( $logfile ).debug"
}


################################################
#
# FUNCTIONS & ASSEMBLIES
#
################################################

# Load all PowerShell Code
"Loading..."
Get-ChildItem -Path ".\$( $functionsSubfolder )" -Recurse -Include @("*.ps1") | ForEach-Object {
    . $_.FullName
    "... $( $_.FullName )"
}

# Load all exe and dll files in subfolder
$libExecutables = Get-ChildItem -Path ".\$( $libSubfolder )" -Recurse -Include @("*.exe","*.dll") 
$libExecutables | ForEach {
    "... $( $_.FullName )"
}


################################################
#
# LOG INPUT PARAMETERS
#
################################################

# Start the log
Write-Log -message "----------------------------------------------------"
Write-Log -message "$( $modulename )"
Write-Log -message "Got a file with these arguments: $( [Environment]::GetCommandLineArgs() )"

# Check if params object exists
if (Get-Variable "params" -Scope Global -ErrorAction SilentlyContinue) {
    $paramsExisting = $true
} else {
    $paramsExisting = $false
}

# Log the params, if existing
if ( $paramsExisting ) {
    $params.Keys | ForEach-Object {
        $param = $_
        Write-Log -message "    $( $param )= ""$( $params[$param] )"""
    }
}


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# MORE SETTINGs
#-----------------------------------------------

$extractTimestamp = Get-Unixtime 
$earliestDate = "2021-01-10T00:00:00Z" # [Datetime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssK")
$extractMode = $params.method 

Write-Log -message "Doing extract mode '$( $extractMode )'"



#-----------------------------------------------
# LOAD LAST EXTRACT
#-----------------------------------------------

# If file is present
If ( Test-Path -Path $lastSessionFile ) {
    $startFromScratch = $false
    $lastSession = Get-Content -Path "$( $lastSessionFile )" -Encoding UTF8 -Raw | ConvertFrom-Json
    $lastLoad = ( Get-DateTimeFromUnixtime -unixtime $lastSession.timestamp ).ToString("yyyy-MM-ddTHH:mm:ssK")
    Write-Log -message "Found session file, last load was at '$( $lastLoad )'"

# If there is no recent session available
} else {
    $startFromScratch = $true
    $lastSession = [PSCustomObject]@{}
    $lastLoad = $earliestDate
    Write-Log -message "No session file found"

}


#-----------------------------------------------
# AUTHENTICATION
#-----------------------------------------------

Write-Log -message "Preparing the authentication"

$apiRoot = $settings.base
#$contentType = "application/json; charset=utf-8"
$auth = "$( Get-SecureToPlaintext -String $settings.login.authenticationHeader )"
$header = @{
    "Authorization" = $auth
}


#-----------------------------------------------
# LOAD DEFINITION
#-----------------------------------------------

# TODO [x] Eventually add a "first" load definition

Write-Log -message "Loading sync definitions"

. ".\10__load_def.ps1"


#-----------------------------------------------
# LOAD DATA
#-----------------------------------------------

Write-Log -message "Loading function for syncing inxmail data"
function Get-Inxmail {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][PSCustomObject] $definition
        ,[Parameter(Mandatory=$true)][String] $extractMode
        ,[Parameter(Mandatory=$false)][PSCustomObject] $parentObj
        ,[Parameter(Mandatory=$false)][bool] $firstLoad = $false
    )
    
    begin {
        
        # Variable definitions
        $inxArr = [System.Collections.ArrayList]@()

        # Load definitions to do now and filter out some jobs, if not the first load
        #$definitions = $definition | where { $_.extract.type -eq $extractMode }
        #if ( -not $firstLoad ) {
        #    $definitions = $definitions | where { $_.extract.onlyOnFirstLoad -ne $true}
        #}

        # Screen through all extracts to do
        $definitions = [System.Collections.ArrayList]@()
        $definition | ForEach {
            $parent = $_
            $parent | select -expand extract | where { $_.type -eq $extractMode } | ForEach {
                $extract = $_
                if ( -not $extract.parent ) { # In subobjects it can be, the parent elements are already defined
                    $extract | Add-Member -MemberType NoteProperty -Name "parent" -Value $parent
                }
                if ( ( -not $firstLoad -and $extract.onlyOnFirstLoad -ne $true ) -or $firstLoad ) {
                    [void]$definitions.Add($extract)
                }
            } 
        }

        # Check if this function should be executed or not, it is important for calling nested objects in a tree
        $doIt = $true
        If ( $parentObj ) {
            If ( $definitions.parent.filter ) {
                If ( -not $definitions.parent.filter.InvokeReturnAsIs() ) {
                    $doIt = $false
                }
            }
        }

    }
    
    process {

        If ( $doIt ) {

            $definitions | ForEach {

                $loadDef = $_.parent
                $extractSettings = $_
                
                # Parse object url, if needed
                If ( $loadDef.object -is [scriptblock] ) {
                    $objectUrl = $loadDef.object.InvokeReturnAsIs()
                } else {
                    $objectUrl = $loadDef.object
                }

                Write-Log -message "Loading '$( $objectUrl )'"

                # Generate URI and additional query parameters
                if ( $extractSettings.nextLink ) {
                    $uri = $extractSettings.nextLink
                } else {
                    $uri = "$( $apiRoot )$( $objectUrl )"
                }
                if ( $extractSettings.parameters ) {
                    $uri = Add-HttpQueryPart -Uri $uri -QueryParameter $extractSettings.parameters
                }

                # Prepare http parameters
                $params = [hashtable]@{
                    Method = "Get"
                    Uri = $uri
                    Header = $header
                    ContentType = "application/hal+json; charset=utf-8"
                    Verbose = $true
                }

                # Load data in pages
                Do {

                    Write-Log -message "Requesting $( $params.Uri )"

                    $res = $null
                    #$res = Invoke-RestMethod @params
                    $result = Invoke-WebRequest @params # Doing webrequests to read the current api limits
                    $res = [System.Text.Encoding]::UTF8.GetString($result.Content) | ConvertFrom-Json

                    
                    <#

                     TODO [ ] implement the ratelimits (current 600 per minute). Just set a timer and wait until calls are resetted. This can be called like:

                    $result.Headers.Keys | where { $_ -like "x-ratelimit*" }
                    x-ratelimit-limit
                    x-ratelimit-remaining
                    x-ratelimit-reset

                    and looks like 

                    Key                       Value                                                                 
                    ---                       -----                                                                 
                    x-ratelimit-limit         600                                                                   
                    x-ratelimit-remaining     599                                                                   
                    x-ratelimit-reset         59         
                    
                    #>
                    
                    # Parse the data
                    $records = [System.Collections.ArrayList]@()
                    if ( $res._embedded ) {
                        $urnFieldName = $loadDef.urn
                        $firstProperty = ( $res._embedded | Get-Member -MemberType NoteProperty | select -first 1 ).Name
                        $records = $res._embedded.$firstProperty  #$res._embedded."inx:$( $loadDef.object  )"
                        $value =  $records | select @{name="object";expression={ $objectUrl }},
                                                    @{name="urn";expression={ $_.$urnFieldName }},
                                                    @{name="parenturn";expression={ $loadDef.parent.InvokeReturnAsIs() }},
                                                    @{name="extract";expression={ $extractTimestamp }},
                                                    @{name="method";expression={ $extractSettings.type }},
                                                    @{name="payload";expression={ ConvertTo-Json -InputObject $_ <#-Compress#> }}
                        #try {
                            [void]$inxArr.AddRange(
                                [System.Collections.ArrayList]@( $value )
                            )
                        #} catch {
                        #    [void]$inxArr.Add($value)
                        #    "Hello world"
                        #}
                    }

                    $params.Uri = $res._links.next.href 

                } While ( $res._links.next )

                # Link for next time
                $nextLink = $res._links."inx:upcoming".href
                #Write-Host $nextLink
                if ( $nextLink -and $extractSettings.rememberUpcomingLink ) {
                    [void]$script:nextLinks.Add([PSCustomObject]@{
                        name = $objectUrl
                        link = $nextLink
                    })
                }
            
                # Go into subobjects, if defined, maybe recursive
                if ( $loadDef.subObjects -and $records.count -gt 0 ) {
                    $records | ForEach {
                        $record = $_
                        $subRes = Get-Inxmail -definition $loadDef.subObjects -parentObj $record -extractMode $extractMode -firstLoad $firstLoad
                        #try {
                            [void]$inxArr.AddRange( 
                                [System.Collections.ArrayList]@( $subRes )
                            )
                        #} catch {
                        #    "Hallo Welt"
                        #}
                    }
                }
            }
        }

    }
    
    end {
        
        # Return object
        $inxArr

    }

}

$nextLinks = [System.Collections.ArrayList]@()
$inxObjects = [System.Collections.ArrayList]@()

$loadParameters = @{
    "definition" = $loadDefs
    "extractMode" = $extractMode
    "firstLoad" = $startFromScratch
}

Write-Log -message "Loading inxmail data now"

$inxObjects.AddRange(( Get-Inxmail @loadParameters ))

#$inxObjects | Out-GridView
#$inxObjects | where { $_.object -eq "events/tracking-permissions" -and $_.parentUrn -eq '4'  } | Out-GridView

# TODO [x] Work out, if we have newer links -> Is this needed? We still get the upcoming link, even when there was no result

$countModifiedRecords = ( $inxObjects | where { $_.object -ne "attributes" } | measure ).count


################################################
#
# PUT DATA INTO SQLITE DATABASE
#
################################################

# Leave this execution, no new data
if ( $countModifiedRecords -eq 0) {
    Write-Log -message "No new data besides attributes, doing nothing now"
    exit 0
}

#-----------------------------------------------
# PREPARE CONNECTION
#-----------------------------------------------

Write-Log -message "Loading sqlite assembly from '$( $settings.sqliteDll )'"

sqlite-Load-Assemblies -dllFile $settings.sqliteDll

Write-Log -message "Establishing connection to sqlite database '$( $settings.sqliteDB )'"

$retries = 10
$retrycount = 0
$secondsDelay = 2
$completed = $false

while (-not $completed) {
    try {
        #$sqliteConnection = sqlite-Open-Connection -sqliteFile ":memory:" -new
        $sqliteConnection = sqlite-Open-Connection -sqliteFile "$( $settings.sqliteDB )" -new
        Write-Log -message "Connection succeeded."
        $completed = $true
    } catch [System.Management.Automation.MethodInvocationException] {
        if ($retrycount -ge $retries) {
            Write-Log -message "Connection failed the maximum number of $( $retries ) times." -severity ([LogSeverity]::ERROR)
            throw $_
            exit 0
        } else {
            Write-Log -message "Connection failed $( $retrycount ) times. Retrying in $( $secondsDelay ) seconds." -severity ([LogSeverity]::WARNING)
            Start-Sleep -Seconds $secondsDelay
            $retrycount++
        }
    }
}

#-----------------------------------------------
# CREATE TABLE IF IT NOT EXISTS
#-----------------------------------------------

Write-Log -message "Creating table for inxmail data, if it does not exist"

# Create temporary table
$sqliteCommand = $sqliteConnection.CreateCommand()
$sqliteCommand.CommandText = @"
CREATE TABLE IF NOT EXISTS "Data" (
	"object"	TEXT,
	"urn"	    INTEGER,
    "parenturn"	INTEGER,
	"extract"	INTEGER,
    "method"    TEXT,
    "payload"   TEXT
);
"@
[void]$sqliteCommand.ExecuteNonQuery()


#-----------------------------------------------
# PREPARE INSERT STATEMENT
#-----------------------------------------------

Write-Log -message "Preparing for inserting data"

# https://docs.microsoft.com/de-de/dotnet/standard/data/sqlite/bulk-insert
$sqliteTransaction = $sqliteConnection.BeginTransaction()
$sqliteCommand = $sqliteConnection.CreateCommand()
$sqliteCommand.CommandText = "INSERT INTO data (object, urn, parenturn, extract, method, payload) VALUES (:object, :urn, :parenturn, :extract, :method, :payload)"


#-----------------------------------------------
# STATEMENT PARAMETERS
#-----------------------------------------------

$sqliteParameterObject = $sqliteCommand.CreateParameter()
$sqliteParameterObject.ParameterName = ":object"
[void]$sqliteCommand.Parameters.Add($sqliteParameterObject)

$sqliteParameterUrn = $sqliteCommand.CreateParameter()
$sqliteParameterUrn.ParameterName = ":urn"
[void]$sqliteCommand.Parameters.Add($sqliteParameterUrn)

$sqliteParameterParentUrn = $sqliteCommand.CreateParameter()
$sqliteParameterParentUrn.ParameterName = ":parenturn"
[void]$sqliteCommand.Parameters.Add($sqliteParameterParentUrn)

$sqliteParameterExtract = $sqliteCommand.CreateParameter()
$sqliteParameterExtract.ParameterName = ":extract"
[void]$sqliteCommand.Parameters.Add($sqliteParameterExtract)

$sqliteParameterMethod = $sqliteCommand.CreateParameter()
$sqliteParameterMethod.ParameterName = ":method"
[void]$sqliteCommand.Parameters.Add($sqliteParameterMethod)

$sqliteParameterPayload = $sqliteCommand.CreateParameter()
$sqliteParameterPayload.ParameterName = ":payload"
[void]$sqliteCommand.Parameters.Add($sqliteParameterPayload)


#-----------------------------------------------
# INSERT DATA AND COMMIT
#-----------------------------------------------

Write-Log -message "Inserting $( $inxObjects.Count ) rows"

# Inserting the data with 1m records and 2 columns took 77 seconds
$t = Measure-Command {
    # Insert the data
    $inxObjects | ForEach {
        $sqliteParameterObject.Value = $_.object
        $sqliteParameterUrn.Value = $_.urn
        $sqliteParameterParentUrn.Value = $_.parenturn
        $sqliteParameterExtract.Value = $_.extract
        $sqliteParameterMethod.Value = $_.method
        $sqliteParameterPayload.Value = $_.payload
        [void]$sqliteCommand.ExecuteNonQuery()
    }
}

Write-Log -message "Inserted the data in $( $t.TotalSeconds ) seconds and will commit now"

# Commit the transaction
$sqliteTransaction.Commit()


#-----------------------------------------------
# CLEANUP
#-----------------------------------------------

Write-Log -message "Cleaning up"

# Cleaning items that have more than 20 versions
$sqliteCommand = $sqliteConnection.CreateCommand()
$sqliteCommand.CommandText = @"
DELETE
FROM Data
WHERE rowid IN (
		SELECT rowid
		FROM (
			SELECT *, ROWID
				,dense_rank() OVER (
					PARTITION BY "object",
						"urn"
						,"parenturn"
						 ORDER BY "extract" DESC
					) AS r
			FROM Data
			)
		WHERE r > 20

		)
"@
[void]$sqliteCommand.ExecuteNonQuery()

# Compressing data
$sqliteCommand = $sqliteConnection.CreateCommand()
$sqliteCommand.CommandText = @"
VACUUM main
"@
[void]$sqliteCommand.ExecuteNonQuery()



#-----------------------------------------------
# CHECK RESULT
#-----------------------------------------------

# Read the data
$t = Measure-Command {
    $count = sqlite-Load-Data -sqlCommand "Select count(*) as c from data where extract = '$( $extractTimestamp )'" -connection $sqliteConnection
}

Write-Log -message "Queried the data in $( $t.TotalSeconds ) seconds, inserted '$( $count.c )' rows in extract '$( $extractTimestamp )'"


Write-Log -message "Closing connection to sqlite database"

# Close the connection
$sqliteConnection.Dispose()







    <#

    https://apidocs.inxmail.com/xpro/rest/v1/

    [/] /list settings not available to read on 2021-06-11
    [x] /mailings{?createdAfter,createdBefore,modifiedAfter,modifiedBefore,sentAfter,types,listIds,readyToSend,embedded}
    [ ] /regular-mailings{?createdAfter,createdBefore,modifiedAfter,modifiedBefore,sentAfter,sentBefore,types,listIds,readyToSend,mailingStates,embedded},
    [ ] /split-test-mailings{?createdAfter,createdBefore,modifiedAfter,modifiedBefore,sentAfter,listIds,readyToSend}
    [ ] /action-mailings{?createdAfter,createdBefore,modifiedAfter,modifiedBefore,sentAfter,listIds}
    [ ] /trigger-mailings{?createdAfter,createdBefore,modifiedAfter,modifiedBefore,sentAfter,listIds}
    [ ] /subscription-mailings{?createdAfter,createdBefore,modifiedAfter,modifiedBefore,sentAfter,listIds,readyToSend}
    [/] /mailings/{mailingId}/approvals
    [/] /mailings/{id}/links{?types}
    [ ] /links{?mailingIds,types}
    [x] /sendings{?mailingIds,listIds,sendingsFinishedBeforeDate,sendingsFinishedAfterDate}
    [x] /sendings/{sendingId}/protocol
    [x] /attributes
    [x] /recipients{?attributes,subscribedTo,lastModifiedSince,email,attributes.attributeName,trackingPermissionsForLists,subscriptionDatesForLists,unsubscriptionDatesForLists}
    [ ] /test-profiles{?listIds,types,allAttributes}
    [x] /events/subscriptions{?listId,startDate,endDate,types,embedded,recipientAttributes}
    [x] /events/unsubscriptions{?listIds,startDate,endDate,types,embedded,recipientAttributes}
    [/] /imports/recipients/{importId}/files
    [/] /imports/recipients/{importId}/files/{importFileId}/errors
    [x] /bounces{?startDate,endDate,embedded,bounceCategory,listId,mailingId,sendingIds,recipientAttributes}
        /bounces{?startDate,endDate,embedded,bounceCategory,mailingIds,sendingIds,listIds,recipientAttributes}
    [x] /clicks{?sendingId,mailingId,trackedOnly,embedded,startDate,endDate,recipientAttributes,listIds}
        /clicks{?sendingId,trackedOnly,embedded,startDate,endDate,recipientAttributes,mailingIds,listIds}
    [x] /web-beacon-hits{?sendingId,mailingIds,listIds,trackedOnly,embedded,startDate,endDate,recipientAttributes}
    [ ] /blacklist-entries{?lastModifiedSince}
    [x] /statistics/responses{?mailingId}
    [x] /statistics/sendings{?mailingId}
    [/] /text-modules{?listId}
    [ ] /test-mail-groups
    [x] /target-groups{?listId}
    [x] /tracking-permissions{?listIds,recipientIds}
    




    Please note that both request parameters sendingsFinishedBeforeDate and sendingsFinishedAfterDate
    are not recommended to be used for continuous synchronisations. For continuous synchronisation use
    id-based requests to avoid problems of date based synchronization. For this purpose each time you
    reach the last page of a collection you find a link to next page you should request in your next
    scheduled synchronization. A possible problem of date based synchronization could be that most recent
    data is not yet available and would be missed if you request a specific date-time range. For further
    information please read: Long term data synchronization with the upcoming link. https://apidocs.inxmail.com/xpro/rest/v1/#synchronizing

    Long term data synchronization with the upcoming link

    A typical use case is the synchronization of data, where you only want to get new objects in subsequent
    synchronizations. Over longer periods of time, there may be huge amounts of data and the practical way of
    synchronizing is to only look at new data.

    To accommodate this, this API provides a special link on the last page of a collection resource. You can
    save this link and use it as a starting point for a future synchronization. The upcoming link leads to a page
    immediately following your last synchronized page of data. This page will be empty until data is entered into the system.

    Please be aware, new data may not become available instantly upon being entered into the system, as it may be
    stored in write buffers for a while.

    We strongly discourage synchronization based on timestamps for a number of reasons, including write buffers and
    unsynchronized clocks.

    Please also mind, the upcoming link will only return a collection containing new objects, it will not return
    previously retrieved objects, even if they have been changed. If you want to capture all changes to all objects
    of a given type, just get the resource collection of this type.

    If no new data has been entered into the system, following the upcoming link will return an empty collection.

    self            The canonical link to this page.
    first           The link relation for the first page of results.
    next            The link relation for the immediate next page of results.
    inx:upcoming    Links to a possible next page. This next page is only available once further data has been created in the system.






    $ curl 'https://api.inxmail.com/customer/rest/v1/recipients?lastModifiedSince=2018-01-16T11:42:32Z' -i -X GET
    #>








<#

# TODO [ ] Database can be locked like

Creating table for inxmail data, if it does not exist
Ausnahme beim Aufrufen von "ExecuteNonQuery" mit 0 Argument(en):  "database is locked
database is locked"
In C:\Users\Florian\Documents\GitHub\AptecoDesignerActions\preload\inxmailExtract\20__extract_objects.ps1:520 Zeichen:1
+ [void]$sqliteCommand.ExecuteNonQuery()
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : SQLiteException

Preparing for inserting data
Ausnahme beim Aufrufen von "BeginTransaction" mit 0 Argument(en):  "database is locked
database is locked"
In C:\Users\Florian\Documents\GitHub\AptecoDesignerActions\preload\inxmailExtract\20__extract_objects.ps1:530 Zeichen:1
+ $sqliteTransaction = $sqliteConnection.BeginTransaction()
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : SQLiteException

#>




################################################
#
# PACK TOGETHER RESULTS AND SAVE AS JSON
#
################################################

Write-Log -message "Writing session file to '$( $lastSessionFile )'"

$session = [PSCustomObject]@{
    timestamp = $extractTimestamp
    nextLinks = $nextLinks
}

# create json object
# weil json-Dateien sind sehr einfach portabel
$json = $session | ConvertTo-Json -Depth 20 # -compress

# print settings to console
$json

# save settings to file
$json | Set-Content -path $lastSessionFile -Encoding UTF8



################################################
#
# CREATE SUCCESS FILE
#
################################################

Write-Log -message "Checking, if a build file should be generated"

if ( $settings.createBuildNow ) {
    Write-Log -message "Creating file '$( $settings.buildNowFile )'"
    $extractTimestamp | Out-File -FilePath $settings.buildNowFile -Encoding utf8 -Force
}

```