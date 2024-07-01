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
        CreatedNewList = "True"
MessageName = "547 /  PeopleStage Demo"
Username = "absdede"
TransactionId = "e207976f-4438-4094-86ea-c0c85ed4aeb1"
successfulRecipients = "2"
ListId = "258"
Password = "gutentag"
ListName = "547 /  PeopleStage Demo"
UploadSuccessful = "True"
failedRecipients = "0"
scriptPath = "D:\Scripts\Inxmail\Mailing"

    }
}


################################################
#
# NOTES
#
################################################

<#

TODO [ ] implement more logging

#>

################################################
#
# SCRIPT ROOT
#
################################################

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
$moduleName = "INXBROADCAST"
$processId =  $params.TransactionId #[guid]::NewGuid()

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

# Load all exe files in subfolder
#$libExecutables = Get-ChildItem -Path ".\$( $libSubfolder )" -Recurse -Include @("*.exe") 
#$libExecutables | ForEach {
#    "... $( $_.FullName )"
#    
#}

# Load dll files in subfolder
#$libExecutables = Get-ChildItem -Path ".\$( $libSubfolder )" -Recurse -Include @("*.dll") 
#$libExecutables | ForEach {
#    "Loading $( $_.FullName )"
#    [Reflection.Assembly]::LoadFile($_.FullName) 
#}


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
        Write-Log -message "    $( $param ) = ""$( $params[$param] )"""
    }
}


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# MORE SETTINGS FIRST
#-----------------------------------------------

$sendMailing = $setting.sendMailing


#-----------------------------------------------
# AUTHENTICATION
#-----------------------------------------------

$apiRoot = $settings.base
$contentType = "application/hal+json"
$auth = "$( Get-SecureToPlaintext -String $settings.login.authenticationHeader )"
$header = @{
    "Authorization" = $auth
}


#-----------------------------------------------
# GET MAILING / LIST DETAILS 
#-----------------------------------------------

# Splitting MailingName and ListName to get Ids
$mailingIdArray = $params.MessageName -split $settings.nameConcatChar,2
#$listIdArray = $params.ListName -split " / "

# TODO [x] use the split character from settings
# TODO [x] check if mailing exists before using it
if([string]::IsNullOrEmpty($params.MessageName)){
    Write-Log -message "Mailing does not exist"
    throw "Mailing does not exist"
}


$mailingId = $mailingIdArray[0]
$listId = $params.ListId


#-----------------------------------------------------------------
# COPY MAILING
#-----------------------------------------------------------------

$object = "operations"
$endpoint = "$( $apiRoot )$( $object )/mailings?command=copy"

$body = [Hashtable]@{
    mailingId = $mailingId
    listId = $listId
    copyApprovalState = $true
}

$bodyJson = $body | ConvertTo-Json

<#
    Copies the given mailing; this needs to be done in order to send it

    https://apidocs.inxmail.com/xpro/rest/v1/#copy-mailing
#>
$copiedMailingRaw = Invoke-WebRequest -Uri $endpoint -Method Post -Headers $header -Body $bodyJson -ContentType $contentType -Verbose 
$copiedMailing = [System.Text.encoding]::UTF8.GetString($copiedMailingRaw.Content) | ConvertFrom-Json

Write-Log -message "Copied mailing '$( $mailingId )' with new id '$( $copiedMailing.id )' and name '$( $copiedMailing.name )' and type '$( $copiedMailing.type )'"


#-----------------------------------------------------------------
# SCHEDULE/SEND A MAILING 
#-----------------------------------------------------------------

if ( $sendMailing -eq $true ) {

    #-----------------------------------------------------------------
    # SEND A MAILING 
    #-----------------------------------------------------------------

    $object = "sendings"
    $endpoint = "$( $apiRoot )$( $object )"
    $contentType = "application/json; charset=utf-8"
    
    $body = [hashtable]@{
        mailingId = $copiedMailing.id
    }
    
    $bodyJson = $body | ConvertTo-Json
    
    <#
        Broadcasts the mailing to every given recipient instantly

        https://apidocs.inxmail.com/xpro/rest/v1/#_send_a_mailing_continue_sending_of_an_interrupted_sending
    #>
    $sentMailing = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $header -Body $bodyJson -ContentType $contentType -Verbose 
    
} else {

    #-----------------------------------------------------------------
    # SCHEDULE MAILING / BROADCASTING
    #-----------------------------------------------------------------


    $object = "regular-mailings"
    $endpoint = "$( $apiRoot )$( $object )/$( $copiedMailing.id )/schedule"
    # Time is in seconds
    $time = 10

    $date = (Get-Date).AddSeconds( $time ).ToString("yyyy-MM-ddTHH:mm:ssK")

    $body = [hashtable]@{
        scheduleDate = $date # exampleFormat: "2022-04-22T13:29:57+02:00"
    }
    
    $bodyJson = $body | ConvertTo-Json
    
    try{
        <#
            Broadcasts the mailing to every given recipient in $time seconds

            https://apidocs.inxmail.com/xpro/rest/v1/#schedule-regular-mailing
        #>
        $sentMailing = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $header -Body $bodyJson -ContentType $contentType -Verbose 
    
    } catch {

        $e = ParseErrorForResponseBody($_)
        Write-Log -message ( $e | ConvertTo-Json -Depth 20 )
        throw $_.exception

    }

    Write-Log -message "Scheduled mailing successfully with id '$( $sentMailing.id )' at '$( $date )'"

}




################################################
#
# RETURN VALUES TO PEOPLESTAGE
#
################################################

$recipients = $params.successfulRecipients

# put in the source id as the listname
$transactionId = $sentMailing.id

# return object
$return = [Hashtable]@{

    "Recipients"=$recipients
    "TransactionId"=$transactionId
    "CustomProvider"=$moduleName
    "ProcessId" = $processId

}

# return the results
$return

```