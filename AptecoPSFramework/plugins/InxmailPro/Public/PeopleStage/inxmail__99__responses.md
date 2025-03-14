
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

$debug = $true
$responses = $true

#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug ) {
    $params = [hashtable]@{
	    scriptPath= "D:\Scripts\Inxmail\Mailing"
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

<#
TODO [ ] Find out where to activate the global tracking
#>

# Parameters for the calls
$trackedOnly = $true
$attributes = @("urn")
$attributesString = $attributes -join ","


#-----------------------------------------------
# AUTHENTICATION
#-----------------------------------------------

$apiRoot = $settings.base
$contentType = "application/json; charset=utf-8"
$auth = "$( Get-SecureToPlaintext -String $settings.login.authenticationHeader )"
$header = @{
    "Authorization" = $auth
}


#-----------------------------------------------
# LOAD TIMESTAMP FROM LAST LOAD
#-----------------------------------------------


$start = [datetime]::UtcNow.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssK")
$end = [datetime]::UtcNow.AddSeconds(0).ToString("yyyy-MM-ddTHH:mm:ssK")


#-----------------------------------------------
# Opens https://apidocs.inxmail.com/xpro/rest/v1/#retrieve-web-beacon-hits-collection
#-----------------------------------------------

$params = [hashtable]@{
    Method = "Get"
    Uri = "$( $apiRoot )web-beacon-hits?embedded=inx:recipient&recipientAttributes=$( $attributesString )&trackedOnly=$( $trackedOnly )&startDate=$( $start )&endDate=$( $end )"
    Header = $header
    ContentType = "application/hal+json"
    Verbose = $true
}

# /web-beacon-hits{?sendingId,mailingIds,listIds,trackedOnly,embedded,startDate,endDate,recipientAttributes}
# "$( $apiRoot )$( $object )?afterId=$( $i )&pageSize=$( $p )&mailingStates=APPROVED"
$opensRes = Invoke-RestMethod @params
$opens = $opensRes._embedded."inx:web-beacon-hits"

#$opens | ft
$opens | select @{ name="urn"; expression={ $_._embedded."inx:recipient".attributes.urn } }, @{ name="email"; expression={ $_._embedded."inx:recipient".email } }, * | ft


### This is for the OPENS of the Apteco Email Response Gatherer ###
if($responses){
    
    $dataCsv = $opens | select @{ name="urn"; expression={ $_._embedded."inx:recipient".attributes.urn } }, @{ name="email"; expression={ $_._embedded."inx:recipient".email } }, @{name="MessageType"; expression={ "Open" }}, * -ExcludeProperty "_links", "_embedded"

    $path = "D:\Scripts\Inxmail\Mailing\ferge-opens.csv"
    $dataCsv | Export-Csv -Path $path -NoTypeInformation -Verbose -Encoding UTF8 -Delimiter "`t"
}



#-----------------------------------------------
# Clicks https://apidocs.inxmail.com/xpro/rest/v1/#retrieve-click-collection
#-----------------------------------------------

$params = [hashtable]@{
    Method = "Get"
    Uri = "$( $apiRoot )clicks?embedded=inx:recipient&recipientAttributes=$( $attributesString )&trackedOnly=$( $trackedOnly )&startDate=$( $start )&endDate=$( $end )"
    Header = $header
    ContentType = "application/hal+json"
    Verbose = $true
}

$clicksRes = Invoke-RestMethod @params
$clicks = $clicksRes._embedded."inx:clicks"

#$clicks | ft
# TODO [ ] Read out links https://apidocs.inxmail.com/xpro/rest/v1/#_retrieve_mailing_links_collection or https://apidocs.inxmail.com/xpro/rest/v1/#retrieve-all-links
$clicks | select @{ name="urn"; expression={ $_._embedded."inx:recipient".attributes.urn } }, @{ name="email"; expression={ $_._embedded."inx:recipient".email } }, * | ft



### This is for the CLICKS of the Apteco Email Response Gatherer ###
if($responses){
    
    $data = $clicks | select @{ name="urn"; expression={ $_._embedded."inx:recipient".attributes.urn } }, @{ name="email"; expression={ $_._embedded."inx:recipient".email }}, @{ name="MessageType"; expression={ "Click" }}, * -ExcludeProperty "_links", "_embedded"

    $path = "D:\Scripts\Inxmail\Mailing\ferge-clicks.csv"
    $data | Export-Csv -Path $path -NoTypeInformation -Verbose -Encoding UTF8 -Delimiter "`t"

}






#-----------------------------------------------
# Bounces https://apidocs.inxmail.com/xpro/rest/v1/#retrieve-bounce-collection
#-----------------------------------------------

$bouncesRes = Invoke-RestMethod -Method Get -Uri "$( $apiRoot )bounces?embedded=inx:recipient&recipientAttributes=urn&trackedOnly=$( $trackedOnly )" -Header $header -ContentType "application/hal+json" -Verbose
$bounces = $bouncesRes._embedded."inx:bounces"

#$bounces | ft


### This is for the BOUNCES of the Apteco Email Response Gatherer ###
if($responses){
    
    $data = $bounces | select @{ name="urn"; expression={ $_._embedded."inx:recipient".attributes.urn } }, @{ name="email"; expression={ $_._embedded."inx:recipient".email } }, @{name="MessageType"; expression={ "Bounce" }}, * -ExcludeProperty "_links", "_embedded"

    $path = "D:\Scripts\Inxmail\Mailing\ferge-bounces.csv"
    $data | Export-Csv -Path $path -NoTypeInformation -Verbose -Encoding UTF8 -Delimiter "`t"

}
    
# TODO [ ] Remove Columns from ResponseDetails Database 




#-----------------------------------------------
# Blacklist https://apidocs.inxmail.com/xpro/rest/v1/#_retrieve_blacklist_entry_collection
#-----------------------------------------------


#-----------------------------------------------
# Unsubscribes https://apidocs.inxmail.com/xpro/rest/v1/#retrieve-unsubscription-events
#-----------------------------------------------
$params = [hashtable]@{
    Method = "Get"
    Uri = "$( $apiRoot )events/unsubscriptions?embedded=inx:recipient&recipientAttributes=$( $attributesString )&trackedOnly=$( $trackedOnly )&startDate=$( $start )&endDate=$( $end )"
    Header = $header
    ContentType = "application/hal+json"
    Verbose = $true
}

$unsubscribesRes = Invoke-RestMethod @params
$unsubscribes = $unsubscribesRes._embedded."inx:unsubscription-events"


### This is for the UNSUBSCRIPTIONS of the Apteco Email Response Gatherer ###
if($responses){
    
    $data = $unsubscribes | select @{ name="urn"; expression={ $_._embedded."inx:recipient".attributes.urn } }, @{ name="email"; expression={ $_._embedded."inx:recipient".email } }, @{name="MessageType"; expression={ "Unsubscription" }}, * -ExcludeProperty "_links", "_embedded"

    $path = "D:\Scripts\Inxmail\Mailing\ferge-unsubscription.csv"
    $data | Export-Csv -Path $path -NoTypeInformation -Verbose -Encoding UTF8 -Delimiter "`t"

}




# for mailing specific unsubscribes see the sending protocol stuff



#-----------------------------------------------
# Sends -> the sendings should have some buffer in the time frame that is being requested as described here: https://apidocs.inxmail.com/xpro/rest/v1/#retrieve-all-sendings
#-----------------------------------------------

$sendingsFinishedAfterDate = [datetime]::UtcNow.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssK")
$sendingsFinishedBeforeDate = [datetime]::UtcNow.AddSeconds(0).ToString("yyyy-MM-ddTHH:mm:ssK")
$sendingsRes = Invoke-RestMethod -Method Get -Uri "$( $apiRoot )sendings?sendingsFinishedAfterDate=$( $sendingsFinishedAfterDate )&sendingsFinishedBeforeDate=$( $sendingsFinishedBeforeDate )" -Header $header -ContentType "application/hal+json" -Verbose
$sendings = $sendingsRes._embedded."inx:sendings"
$sendings | ft

#https://apidocs.inxmail.com/xpro/rest/v1/#retrieve-sending-protocol-collection

$protocol = [System.Collections.ArrayList]@()
<#
Possible states
NOT_SENT, SENT, RECIPIENT_NOT_FOUND, ERROR, ADDRESS_REJECTED, HARDBOUNCE, SOFTBOUNCE, UNKNOWNBOUNCE, SPAMBOUNCE, MUST_ATTRIBUTE, NO_MAIL
#>

if($responses){
    
    $sendings | ForEach {

        $sending = $_
    
        $protocolRes = Invoke-RestMethod -Method Get -Uri "$( $apiRoot )/sendings/$( $sending.id )/protocol?embedded=inx:recipient&recipientAttributes=urn" -Header $header -ContentType "application/hal+json" -Verbose
        $protocol.AddRange( @( $protocolRes._embedded."inx:protocol-entries" | select @{name="sendingId";expression={ $sending.id }}, @{name="mailingId";expression={ $sending.mailingId }}, @{name="MessageType"; expression={ "Send" }}, * ) )
    
    }
    
    $data = $protocol | select @{ name="urn"; expression={ $_._embedded."inx:recipient".attributes.urn } }, @{ name="email"; expression={ $_._embedded."inx:recipient".email } }, * -ExcludeProperty "_links", "_embedded"
    
    $path = "D:\Scripts\Inxmail\Mailing\ferge-sends.csv"
    $data | Export-Csv -Path $path -NoTypeInformation -Verbose -Encoding UTF8 -Delimiter "`t"
}

exit 0
if($responses){
    & EmailResponseGatherer64.exe .\responses.xml
}

#-----------------------------------------------
# SAVE TIMESTAMP FOR NEXT LOAD
#-----------------------------------------------

#[datetime]::UtcNow.AddSeconds(0).ToString("yyyy-MM-ddTHH:mm:ssK")

```