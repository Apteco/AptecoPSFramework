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
        scriptPath = "D:\Scripts\Inxmail\Mailing"
        TestRecipient = '{"Email":"reply@apteco.de","Sms":null,"Personalisation":{"email":"florian.von.bracht@apteco.de","Kunden ID":"","Vorname":"","Nachname":"","Anrede":"","DEF":"ABC","Gender":"Geschlecht","Communication Key":"4ba54992-3294-49f7-9342-7871148abb2d"}}'
        MessageName = "744 / Orbit Demo Mailing"
        ListName = ""
        Password = "gutentag"
        Username = "absdede"

        
    }
}


################################################
#
# NOTES
#
################################################

<#

https://apidocs.inxmail.com/xpro/rest/v1/

Create a test profile

https://apidocs.inxmail.com/xpro/rest/v1/#create-test-profile

Existing Mailing

https://apidocs.inxmail.com/xpro/rest/v1/#_retrieve_single_mailing_rendered_content
GET /mailings/{id}/renderedContent{?testProfileId,includeAttachments}

Non-existing mailing -> only input html

https://apidocs.inxmail.com/xpro/rest/v1/#temporary-preview
POST /temporary-preview

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
$moduleName = "INXPREVIEW"

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
        Write-Log -message "    $( $param ) = ""$( $params[$param] )"""
    }
}


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# AUTHENTICATION
#-----------------------------------------------

$apiRoot = $settings.base
$contentType = "application/json;charset=utf-8"
$auth = "$( Get-SecureToPlaintext -String $settings.login.authenticationHeader )"
$header = @{
    "Authorization" = $auth
}


#-----------------------------------------------
# GET MAILING
#-----------------------------------------------

$mailingId = $params.MessageName -split " / ",2
$mailingDetailsRaw = Invoke-WebRequest -Method Get -Uri "$( $apiRoot )mailings/$( $mailingId[0] )" -Header $header -ContentType "application/hal+json;charset=utf-8" -Verbose
$mailingDetails = [System.Text.encoding]::UTF8.GetString($mailingDetailsRaw.Content) | ConvertFrom-Json


#-----------------------------------------------
# GET MAILING AND LIST ID
#-----------------------------------------------

$arr = $params.MessageName -split " / ",2

# TODO [ ] use the split character from settings
# TODO [ ] check if list exists before using it

# If a given local list exists in the params change endpoint to that list
# Now recipients will be imported in the given list and not to the global inxmail list
# If there is no list given there will be one created automatically
$object = "lists"
if ($params.ListName -eq "" -or $null -eq $params.ListName -or $params.MessageName -eq $params.ListName) {

    # new list normally, use the one connected to the mailing
    $listID = $mailingDetails.listId

} else {

    # existing list

    # Splitting the ListName with "/" in order to get the listID
    # TODO [ ] use the split character from settings
    $listNameSplit = $params.ListName.Split(" / "),2
    $listID = $listNameSplit[0]


}


#-----------------------------------------------
# GET LIST DETAILS
#-----------------------------------------------

$listDetailsRaw = Invoke-WebRequest -Method Get -Uri "$( $apiRoot )lists/$( $mailingDetails.listId )" -Header $header -ContentType "application/hal+json" -Verbose
$listDetails = [System.Text.encoding]::UTF8.GetString($listDetailsRaw.Content) | ConvertFrom-Json



#-----------------------------------------------
# PARSING TEST RECIPIENT
#-----------------------------------------------

$testRecipient = ConvertFrom-Json -InputObject $params.TestRecipient


#-----------------------------------------------
# ATTRIBUTES FOR TEST RECIPIENT
#-----------------------------------------------

# Comma forces to create an array instead of a string
#$requiredFields = @(,$settings.upload.emailColumnName)

# Load attributes
$object = "attributes"
$endpoint = "$( $apiRoot )$( $object )"

# Get Inxmail attributes
$attributesObjectRaw = Invoke-WebRequest -Method Get -Uri $endpoint -Headers $header -Verbose -ContentType $contentType
$attributesObject = [System.Text.encoding]::UTF8.GetString($attributesObjectRaw.Content) | ConvertFrom-Json

$attributes = $attributesObject._embedded."inx:attributes"
$attributesNames = $attributes.name

# Gets only the NoteProperty MemberTypes of the $dataCsv Object
$csvAttributesObject = $testRecipient.Personalisation | Get-Member -MemberType NoteProperty
$csvAttributesNames = $csvAttributesObject.name

# Check if email field is present in csv
#$equalWithRequirements = Compare-Object -ReferenceObject $csvAttributesNames -DifferenceObject $requiredFields -IncludeEqual -PassThru | Where-Object { $_.SideIndicator -eq "==" }

if ( $equalWithRequirements.count -eq $requiredFields.Count ) {
    # Required fields are all included

} else {

    # Required fields not equal -> error!
    Write-Log -message "No email field present!" -severity ( [LogSeverity]::ERROR )
    throw [System.IO.InvalidDataException] "No email field present!"  

}

# Compare columns
$differences = Compare-Object -ReferenceObject $attributesNames -DifferenceObject $csvAttributesNames -IncludeEqual #-Property Name 
#$colsEqual = $differences | Where-Object { $_.SideIndicator -eq "==" } 
#$colsInAttrButNotCsv = $differences | Where-Object { $_.SideIndicator -eq "<=" } 
$colsInCsvButNotAttr = $differences | Where-Object { $_.SideIndicator -eq "=>" }

$newAttributesList = $colsInCsvButNotAttr | where { @( $settings.upload.emailColumnName, $settings.upload.permissionColumnName ) -notcontains  $_.InputObject  } 

If ( $newAttributesList.Count -gt 0 ) {
    Write-Log -message "Attributes to create: $( $colsInCsvButNotAttr -join "," )"
} else {
    Write-Log -message "No attributes to create"
}

#------------------------------------------------------
# CREATE GLOBAL/LOCAL ATTRIBUTES THAT ARE NOT IN CSV
#------------------------------------------------------

$object = "attributes"
$endpoint = "$( $apiRoot )$( $object )"
# The new attributes that are going to be added
$newAttributes = @()
$newAttributeName = $null
$bodyJson = $null
$body = $null

# For each object in the CSV that was not in the attributes
$newAttributesList | ForEach-Object {

    # Getting the Attribute Name
    $newAttributeName = $_.InputObject
    
    # If Attribute isn't email (as this is already given), then it will be created
    $body = @{
        "name" = "$( $newAttributeName )"
        # We assume that each entry will be from type "TEXT"
        "type" = "TEXT"                     # TEXT|DATE_AND_TIME|DATE_ONLY|TIME_ONLY|INTEGER|FLOATING_POINT_NUMBER|BOOLEAN
        "maxLength" = 255
    }

    $bodyJson = $body | ConvertTo-Json
    # Server gibt schon ein Hashtable zurück
    <#
        https://apidocs.inxmail.com/xpro/rest/v1/#_create_recipient_attribute
    #>
    $newAttributes += Invoke-RestMethod -Uri $endpoint -Method Post -Headers $header -Body $bodyJson -ContentType $contentType -Verbose
     
    Write-Log -message "Created new attribute with name '$( $newAttributeName )'"

}   

#-----------------------------------------------
# GET ALL TEST PROFILES
#-----------------------------------------------

# TODO [ ] paging
$testProfilesResRaw = Invoke-WebRequest -Method Get -Uri "$( $apiRoot )test-profiles" -Header $header -ContentType "application/hal+json" -Verbose
$testProfilesRes = [System.Text.encoding]::UTF8.GetString($testProfilesResRaw.Content) | ConvertFrom-Json

$testProfiles = $testProfilesRes._embedded.'inx:test-profiles'

$latestProfile = $testProfiles | where { $_.email -eq $testRecipient.Email } | sort id -Descending | select -first 1


#-----------------------------------------------
# CREATE/UPDATE TEST PROFILE
#-----------------------------------------------

# Exclude some properties that we don't need
$personalisationObj = [PSCustomObject]@{}
$testRecipient.Personalisation.PSObject.Properties | where { @( $settings.upload.emailColumnName, $settings.upload.permissionColumnName ) -notcontains  $_.Name -and $_.MemberType -eq "NoteProperty" } | % { $personalisationObj | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value }

# Create the body
$body = @{
    "email" = $testRecipient.Email
    "trackingPermission" = $true
    "attributes" = $personalisationObj
    "description" = "Description"
}

# Try to update the test profile
try {

    # Choose if update or create
    if ( $latestProfile ) {
        $verb = "Patch"
        $uri = $latestProfile._links.self.href
        $contentType = "application/merge-patch+json;charset=utf-8"
    } else {
        $verb = "Post"
        $uri = "$( $apiRoot )test-profiles" 
        $contentType = "application/hal+json;charset=utf-8"
        $body.add("listId", 1 ) # Add global list id, if new profile
    }

    $bodyJson = ConvertTo-Json -InputObject $body

    # TODO [ ] Didn't found the info, where to create the list dependent profiles: https://help.inxmail.com/en/content/xpro/testprofile_erstellen.htm
    $testProfile = Invoke-RestMethod -Method $verb -Uri $uri -Header $header -ContentType $contentType -Verbose -Body $bodyJson

} catch {

    $e = ParseErrorForResponseBody($_)
    Write-Log -message ( $e | ConvertTo-Json -Depth 20 )
    throw $_.exception

}

# Get that new or updated profile
$previewProfileRaw = Invoke-WebRequest -Method Get -Uri $testProfile._links.self.href -Header $header -ContentType "application/hal+json" -Verbose
$previewProfile = [System.Text.encoding]::UTF8.GetString($previewProfileRaw.Content) | ConvertFrom-Json

#$profile.id


#-----------------------------------------------
# RENDER MAILING
#-----------------------------------------------
# https://apidocs.inxmail.com/xpro/rest/v1/#_retrieve_single_mailing_rendered_content
# /mailings/{id}/renderedContent{?testProfileId,includeAttachments}

try {


    $renderedResRaw = Invoke-WebRequest -Method Get -Uri "$( $apiRoot )mailings/$( $mailingDetails.id )/renderedContent?testProfileId=$( $previewProfile.id )" -Header $header -ContentType "application/hal+json" -Verbose

} catch {

    $e = ParseErrorForResponseBody($_)
    Write-Log -message ( $e | ConvertTo-Json -Depth 20 )
    throw $_.exception

}


$renderedRes = [System.Text.encoding]::UTF8.GetString($renderedResRaw.Content) | ConvertFrom-Json



################################################
#
# RETURN VALUES TO PEOPLESTAGE
#
################################################

# return object
$return = [Hashtable]@{
    "Type" = "Email" #Email|Sms
    "FromAddress"=$listDetails.senderAddress
    "FromName"=$listDetails.senderName
    "Html"=$renderedRes.html
    "ReplyTo"=$listDetails.replyToAddress
    "Subject"=$renderedRes.subject
    "Text"=$renderedRes.text
}

# return the results
$return



```