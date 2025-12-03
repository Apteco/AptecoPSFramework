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

if( $debug ){
    $params = [hashtable]@{
        TransactionType = "Replace"
        Password = "gutentag"
        scriptPath = "D:\Scripts\Inxmail\Mailing"
        MessageName = "547 /  PeopleStage Demo"
        EmailFieldName = "email"
        SmsFieldName = ""
        Path = "D:\faststats\Publish\B2B\system\Deliveries\PowerShell_547   PeopleStage Demo_f4ae39f1-18bb-4bb6-bd3a-d092f9e011a4.txt"
        ReplyToEmail = "reply@apteco.de"
        Username = "absdede"
        ReplyToSMS = ""
        UrnFieldName = "ContactId"
        ListName = "547 /  PeopleStage Demo"
        CommunicationKeyFieldName = "Communication Key"
    }
}


################################################
#
# NOTES
#
################################################

<#

TODO [ ] more log comments

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
$settingsFilename = "settings.json"
$moduleName = "INXUPLOAD"
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

# Load all PowerShell Code (Functions aswell)
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
# -ErrorAction is that in case "params" does not exist it would return an error
# to avoid the error message the error is skipped via SilentlyContinue
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
$contentType = "application/hal+json;charset=utf-8"
$auth = "$( Get-SecureToPlaintext -String $settings.login.authenticationHeader )"
$header = @{
    "Authorization" = $auth
}


#-----------------------------------------------
# LOAD DATA
#
# Input: People Stage returns a text file table with a "`t" delimiter
# Output: Inxmail needs a .csv file and the first column to be "email"
#-----------------------------------------------

# File where the Path is with ending .txt
$file = Get-Item -Path $params.Path

# Transform PeopleStage data into csv file
$dataCsv = [System.Collections.ArrayList]@( import-csv -Path $file.FullName -Delimiter "`t" -Encoding UTF8 )

# Transform csv into compatible inxmail csv file (meaning that email field is in first place)
$props = $dataCsv | Get-Member -MemberType NoteProperty

# Only add the granted column, if not present
# TODO [ ] add and prove this logic, otherwise no tracking will be possible
If ( $props.Name -notcontains $settings.upload.permissionColumnName ) {
    $dataCsv = $dataCsv | Select *, @{name="$( $settings.upload.permissionColumnName )";expression={ "GRANTED"  }}
    $props = $dataCsv | Get-Member -MemberType NoteProperty
}

# add urn column always - it is needed later for response matching
$urnFieldName = $params.UrnFieldName
$dataCsv = $dataCsv | Select *, @{name="urn";expression={ $_.$urnFieldName }}

# Redefine the properties now
$props = $dataCsv | Get-Member -MemberType NoteProperty


# Make sure the email column has the right name
if ( $params.EmailFieldName -ne "email" ) {
    Write-Log -message "Please make sure, the email column name is 'email' in the channel editor" -severity ( [LogSeverity]::ERROR )
    throw [System.IO.InvalidDataException] "Please make sure, the email column name is 'email' in the channel editor"
}

# Adding first column directly to the array
$columnOrder = @("email") 
$props.Name | Where-Object { $_ -notin $columnOrder } | ForEach-Object {
    $columnOrder += $_
}

# Rearranging the order that email is the first column as this is a requirement of inxmail
$csvString = $dataCsv | Select-Object $columnOrder | ConvertTo-Csv -Delimiter ";" -NoTypeInformation   #| Export-Csv -Path $path -Encoding UTF8 -Delimiter ";" -Verbose -NoTypeInformation


#-----------------------------------------------
# ATTRIBUTES
# 
# It is checked whether all attributes of the .csv file
# are integrated in Inxmail; if not, they will be added
# "email"-field will always be the default
# 
#-----------------------------------------------

# Comma forces to create an array instead of a string
$requiredFields = @(,$params.EmailFieldName)

# Load attributes
$object = "attributes"
$endpoint = "$( $apiRoot )$( $object )"

<#
    INVOKE No. 1
    https://apidocs.inxmail.com/xpro/rest/v1/#_retrieve_recipient_attributes_collection
    
    Returns all the attributes that are already in Inxmail. ???
#>
$attributesObjectRaw = Invoke-WebRequest -Method Get -Uri $endpoint -Headers $header -Verbose -ContentType $contentType
$attributesObject = [System.Text.encoding]::UTF8.GetString($attributesObjectRaw.Content) | ConvertFrom-Json
$attributes = $attributesObject._embedded."inx:attributes"
$attributesNames = $attributes.name

<#
    NoteProperties are generic properties that are created by Powershell.

    Properties of PS custom objects will be NoteProperty, as will the properties of objects created with Import-CSV,
    or created by using Select-Object and specifying properties to select.
#>
# Gets only the NoteProperty MemberTypes of the $dataCsv Object
$csvAttributesObject = Get-Member -InputObject $dataCsv[0] -MemberType NoteProperty 
$csvAttributesNames = $csvAttributesObject.name

# Check if email field is present in csv
$equalWithRequirements = Compare-Object -ReferenceObject $csvAttributesNames -DifferenceObject $requiredFields -IncludeEqual -PassThru | Where-Object { $_.SideIndicator -eq "==" }

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
$colsInCsvButNotAttr | where { @( $settings.upload.emailColumnName, $settings.upload.permissionColumnName ) -notcontains  $_.InputObject  } | ForEach-Object {

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
     
}   


#-----------------------------------------------
# CHECK IF LIST EXISTS, IF NOT CREATE NEW LIST
#-----------------------------------------------

$arr = $params.MessageName -split $settings.nameConcatChar,2 # TODO Maybe use -split "x",2,"SimpleMatch" ?

# TODO [x] use the split character from settings
# TODO [x] check if list exists before using it
if([String]::IsNullOrEmpty($params.ListName)){
    Write-Log -message "Mailing does not exist"
    throw "Mailing does not exist"
}

# If a given local list exists in the params change endpoint to that list
# Now recipients will be imported in the given list and not to the global inxmail list
# If there is no list given there will be one created automatically
$object = "lists"
if ($params.ListName -eq "" -or $null -eq $params.ListName -or $params.MessageName -eq $params.ListName) {

    $createdNewList = $true

    $endpoint = "$( $apiRoot )$( $object )"
    
    # Neue Liste wird hinzufügt
    $bodyBeta = @{
        "name" = [datetime]::Now.ToString("yyyyMMddHHmmss") #"$( [datetime]::Now.ToString("MM.dd.yyyy-HH:mm:ss") )_ID:$( $arr[0] )_Name:$( $arr[1] )"
        "type" = $settings.newList.type
        
        # TODO [x] put senderAddress and other info into settings and read from there
        "senderAddress" = $settings.newList.senderAddress
        #"senderName" = "Sibylle"
        # "replyToAddress" = "jane.doe@example.com"
        # "replyToName" = "Jane Doe"
        
        "description" = $settings.newList.description
    }

    $bodyBetaJson = $bodyBeta | ConvertTo-Json

    #$upload = @()
    try {

        <#
            https://apidocs.inxmail.com/xpro/rest/v1/#_create_mailing_list
        #>
        $upload = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $header -Body $bodyBetaJson -ContentType $contentType -Verbose
        $listID = $upload.id

    } catch {

        $e = ParseErrorForResponseBody($_)
        Write-Log -message ( $e | ConvertTo-Json -Depth 20 )
        throw $_

    }

} else {

    # Splitting the ListName with "/" in order to get the listID
    # TODO [x] use the split character from settings
    $listNameSplit = $params.ListName -Split $settings.nameConcatChar,2
    $listID = $listNameSplit[0]
    # Endpoint is the list with the corresponding listID
    
    $createdNewList = $false

}


#-----------------------------------------------
# UPSERT DATA INTO LISTS
#-----------------------------------------------

# A certain method to correctly invoke
$multipart = ConvertTo-MultipartUpload -string $csvString

# Dem server gibt man Informationen mit über das Format, was es für den server leichter macht
$object = "imports/recipients"
$endpoint = "$( $apiRoot )$( $object )?listId=$( $listID )"

<#
    Now the data is going to be uploaded to Inxmail

    https://apidocs.inxmail.com/xpro/rest/v1/#_import_multiple_recipients_by_uploading_a_csv_file
#>
$upload = [System.Collections.ArrayList]@( Invoke-RestMethod -Uri $endpoint -Method Post -Headers $header -Body $multipart.body -ContentType $multipart.contentType -Verbose )

Write-Log -message "Created upload with id '$( $upload.id )'"


#-----------------------------------------------
# WAIT UNTIL IMPORT IS DONE
#-----------------------------------------------

$check = $null
$sleepTime = 4
$totalSleepTime = 0

$object = "imports/recipients/"
$endpoint = "$( $apiRoot )$( $object )$( $upload.id )"
$contentType = "application/hal+json"


do {
    <#
        Here it is being checked every 4 secondes if the import status has succeeded or not
        If it has succeeded it will exit the loop as status will not be PROCESSING

        https://apidocs.inxmail.com/xpro/rest/v1/#observe-import-status
    #>
    $check = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $header -ContentType $contentType -Verbose

    Write-Host $check.state
    Start-Sleep -Seconds $sleepTime
    $totalSleepTime += $sleepTime
    Write-Host $totalSleepTime
    
} while ( @("SUCCESS","FAILED","CANCELED") -notcontains $check.state)
        
Write-Log -message "Got back status '$( $check.state )' after $( $totalSleepTime ) seconds"
Write-Log -message "$( $check.successCount ) records uploaded successfully"
Write-Log -message "$( $check.failCount ) records uploaded failed"

# TODO [x] retrieve errors if they happen: https://apidocs.inxmail.com/xpro/rest/v1/#_retrieve_import_errors_collection

# if the sum of errors are greater than 0 -> at least one error
if($check.failCount -gt 0){
    $i = 0
    $uploadSuccessful = $false
    # do until loop iterates over all existing errors and writing the error kind in the log
    do{
        $endpoint = "$( $settings.base )imports/recipients/$( $check.id )/files/$( $check.id )/errors"

        <#
            https://apidocs.inxmail.com/xpro/rest/v1/#_retrieve_import_errors_collection
        #>
        $errors = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $header -ContentType $contentType -Verbose
        Write-Log -message "Error No. $( $i+1 ): $( $errors._embedded."inx:errors".error )"
        Write-Log -message "Value: $( $errors._embedded."inx:errors".value )"
        $i++
    }until($check.failCount -gt $i)

}else{
    $uploadSuccessful = $true
}

################################################
#
# RETURN VALUES TO PEOPLESTAGE AND BROADCAST
#
################################################

# count the number of successful upload rows
$recipients = $check.successCount

# put in the source id as the listname
$transactionId = $processId

# TODO [x] put in boolean to only do broadcast, if upload was successful

# return object
$return = [Hashtable]@{

    "Recipients"=$recipients
    "TransactionId"=$transactionId
    "successfulRecipients" = $recipients
    "failedRecipients" = $check.failCount

    # List information
    "CreatedNewList" = $createdNewList
    "ListId" = $listID
    "UploadSuccessful" = $uploadSuccessful

}

# return the results
$return

```