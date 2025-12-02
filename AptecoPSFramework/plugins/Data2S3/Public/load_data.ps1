################################################
#
# START
#
################################################

#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

# TODO put the whole thing here into a function

# TODO use a date as input
param(

    [Parameter(Mandatory=$false)]
     [string]$ScriptPath = "C:\FastStats\Scripts\Data2S3"
    
    #[Parameter(Mandatory=$false)][string]$HanaSettingsFile = "C:\faststats\scripts\hana\check-connection\settings.json"
    
    # String of data sources to extract
    #,[Parameter(Mandatory=$false)]
    # [String[]]$Include = [Array]@()
    
    ,[Parameter(Mandatory=$false)]
     [String]$StartDate = [DateTime]::Today.AddDays(-1).ToString("yyyy-MM-dd")

)

$processStart = [datetime]::now


#-----------------------------------------------
# IMPORT MODULES
#-----------------------------------------------

Import-Module WriteLog, EncryptCredential, powershell-yaml, SQLPS, ImportDependency, ConvertStrings, awspowershell, MeasureRows

# load assemblies
# Add-Type -AssemblyName System.Security

$psEnv = Get-PSEnvironment -SkipBackgroundCheck


#-----------------------------------------------
# FIND OUT ABOUT 64bit
#-----------------------------------------------

if ($psEnv.Is64BitProcess -eq $True) {
    Write-Log "PowerShell is running in 64-bit mode."
} else {
    Write-Log "PowerShell is running in 32-bit mode." -Severity WARNING
    Exit 4
}


################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# DEFINE SETTINGS
#-----------------------------------------------

Set-Location $ScriptPath

# Import settings file
$settingsFile = ".\d2s.yaml"
$absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settingsFile)
#$settings = [PSCustomObject]( Get-Content -Path $absolutePath -Encoding utf8 -Raw | ConvertFrom-Yaml -Ordered )

# TODO load the settings file
# TODO put duckdb.exe in bin folder

# Log
$Script:logDivider = "----------------------------------------------------" # String used to show a new part of the log

# SqlServer
$sqlParams = [Hashtable]@{
    "ServerInstance" = $Script:settings.sqlserver.instance
    "Database" = $Script:settings.sqlserver.database
    "Username" = $Script:settings.sqlserver.username
    "Password" = Convert-SecureToPlaintext -String $Script:settings.sqlserver.password
}

# DuckDB
$duckDatabase = $Script:settings.duckdb.Database
Set-Alias duckdb $Script:settings.duckdb.Path

# AWS S3 Credentials
$awsS3 = [hashtable]@{
    "BucketName" = $Script:settings.S3.BucketName
    "Credential" = [Amazon.Runtime.BasicAWSCredentials]::new($Script:settings.S3.AccessKey,( Convert-SecureToPlaintext $Script:settings.S3.SecretKey ))
    "Region" = $Script:settings.S3.Region
}


#-----------------------------------------------
# SETUP LOG
#-----------------------------------------------

$processId = [guid]::NewGuid()
Set-Logfile $Script:settings.logfile
Set-ProcessId -Id $processId
Write-Log -message $Script:logDivider



Write-Log "Check input parameter"

# Check the input date
Write-Log "  StartDate: $( $StartDate )"
try {
    $tryDate = [DateTime]::ParseExact($StartDate,"yyyy-MM-dd",$null)
    Write-Log "    Date is valid"
} catch {
    Write-Log "    Date is invalid. Exiting..." -Severity ERROR
    Exit 4
}


################################################
#
# PROCESS
#
################################################

#-----------------------------------------------
# GET ALL FILES FROM THAT SPECIFIC DAY...
#-----------------------------------------------

$filesToday = @( Get-ChildItem -Path $Script:settings.folderToCheck -Filter "*.txt" | Where-Object { $_.LastWriteTime.toString("yyyy-MM-dd") -eq $StartDate } )

If ( $filesToday.Count -eq 0 ) {
    Write-Log "No files to check for this day. Exiting..."
    Exit 0
} else {
    Write-Log "There are $( $filesToday.Count ) files to check on $( $StartDate )"
}


try {

    #-----------------------------------------------
    # ... AND COPY THEM OVER
    #-----------------------------------------------

    $tempPath = Get-TemporaryPath
    $tempDir = New-Item -Path $tempPath -Name $processId -ItemType Directory
    Write-Log "Created '$( $tempDir.FullName )' and copy files over"

    $filesToday | ForEach-Object {
        $fileItem = $_
        Copy-Item -Path $fileItem.FullName -Destination $tempDir.FullName
    }


    #-----------------------------------------------
    # GET THEIR METADATA FROM SQLSERVER
    #-----------------------------------------------

    $deliveryFiles = Get-ChildItem -Path $tempDir.FullName
    $sqlCampaignMetadataQuery = Get-Content -Path ".\sql\10_campaign_metadata.sql" -Encoding utf8 -Raw

    Write-Log "Loading campaign Metadata"
    $deliveryMetaData = [System.Collections.ArrayList]::new()
    $deliveryFiles | ForEach-Object {
        $deliveryItem = $_
        Write-Log "  Campaign with file '$( $deliveryItem.Name )'"
        $deliveryMetaDataQuery = $sqlCampaignMetadataQuery -replace "#FILE#",$deliveryItem.Name
        $deliveryMetaDataResult = Invoke-Sqlcmd @sqlParams -Query $deliveryMetaDataQuery # -Credential is not available with SQLPS, better use SqlServer then
        $deliveryMetaData.Add( $deliveryMetaDataResult ) | Out-Null
        Write-Log "    Campaign ID: $( $deliveryMetaDataResult.CampaignId )"
        Write-Log "    Step ID: $( $deliveryMetaDataResult.DeliveryStepId )"
        Write-Log "    Run: $( $deliveryMetaDataResult.Run )"
    }


    #-----------------------------------------------
    # BUILD WERBECODES
    #-----------------------------------------------

    Write-Log "Using DuckDB database: $( $duckDatabase )"

    Write-Log "Creating Werbecode table if not exists"
    $sqlWerbecodesCreate = Get-Content -Path ".\sql\28_create_werbecode.sql" -Encoding utf8 -Raw
    duckdb $duckDatabase -c $sqlWerbecodesCreate

    Write-Log "Insert new Werbecodes"
    $sqlWerbecodesInsert = Get-Content -Path ".\sql\29_build_werbecodes.sql" -Encoding utf8 -Raw
    $replacements = [Hashtable]@{
        "#TEMPDIR#" = $tempDir.FullName
    }
    $sqlWerbecodesQuery = Set-Token -InputString $sqlWerbecodesInsert -Replacements $replacements

    # => Wichtig, dass bei reinen Exporten vielleicht gar nicht zum Projekt geloggt wird, sondern über einen Extra Schritt als Dateikanal
    duckdb $duckDatabase -c $sqlWerbecodesQuery


    #-----------------------------------------------
    # GET CAMPAIGN HISTORY
    #-----------------------------------------------

    $sqlCampaignHistoryQuery = Get-Content -Path ".\sql\20_communication_history.sql" -Encoding utf8 -Raw

    Write-Log "Loading campaign history"
    $campaignHistory = [System.Collections.ArrayList]::new()
    $deliveryMetaData | ForEach-Object {
        $delivery = $_
        Write-Log "  Delivery with campaign '$( $delivery.CampaignId )' - '$( $delivery.Name )' and run '$( $delivery.Run )'"
        $replacements = [Hashtable]@{
            "#CAMPAIGN#" = $delivery.CampaignId
            "#RUN#" = $delivery.Run
            "#STEP#" = $delivery.DeliveryStepId
            "#FILEGUID#" = $delivery.FileGUID
        }
        $campaignHistoryQuery = Set-Token -InputString $sqlCampaignHistoryQuery -Replacements $replacements
        $campaignHistoryResult = @( Invoke-Sqlcmd @sqlParams -Query $campaignHistoryQuery )
        $campaignHistory.AddRange( $campaignHistoryResult ) | Out-Null
        Write-Log "    Loaded $( $campaignHistoryResult.Count ) records"
    }


    #-----------------------------------------------
    # EXPORT CAMPAIGN HISTORY AS FILE
    #-----------------------------------------------

    $campaignHistoryFile = Join-Path -Path $tempDir.FullName -ChildPath "campaignhistory.csv"
    $campaignHistory | Export-Csv -Path $campaignHistoryFile -Encoding utf8 -NoTypeInformation -Delimiter "`t"


    #-----------------------------------------------
    # LOAD COMMUNICATION DATA FROM DELIVERY FILES
    #-----------------------------------------------

    # TODO Filter earlier deliveries only where a communication key is integrated
    # TODO What to do with entries without a project => currently just ignored

    # Currently only matching via communication key, could be extended to join via PE Interne ID or PE Externe Id
    # TODO use these fields automatically    $Script:settings.alwaysUpload # fields that need to be present
    $exportFileName = "export.csv"
    $exportFile = Join-Path -Path $tempDir -ChildPath $exportFileName
    $sqlJoinQueryTemplate = Get-Content -Path ".\sql\30_join_and_export.sql" -Encoding utf8 -Raw
    $replacements = [Hashtable]@{
        "#TEMPDIR#" = $tempDir.FullName
        "#HISTORY#" = $campaignHistoryFile
        "#EXPORTFILE#" = $exportFile
    }
    $sqlJoinQuery = Set-Token -InputString $sqlJoinQueryTemplate -Replacements $replacements

    # => Wichtig, dass bei reinen Exporten vielleicht gar nicht zum Projekt geloggt wird, sondern über einen Extra Schritt als Dateikanal
    duckdb $duckDatabase -c $sqlJoinQuery

    Write-Log "Exported a file to '$( $exportFile )'"


    #-----------------------------------------------
    # CHECK THE OUTPUT
    #-----------------------------------------------

    $totalRows = Measure-Row -Path $exportFile -SkipFirstRow

    Write-Log "The exported file contains '$( $totalRows )' rows"
    

    #-----------------------------------------------
    # WRITE FILE AND UPLOAD TO S3
    #-----------------------------------------------

    # TODO Join csv files with duck and upload?
    # TODO write files with AWS module or duckdb?
    
    If ( $totalRows.Count -gt 0 ) {
        $metadata = @{
            'x-amz-meta-uploadedby' = $Script:settings.S3.Meta.UploadedBy
            'x-amz-meta-department' = $Script:settings.S3.Meta.Department
        }
        $uploadKey = "sextant/$( $StartDate )/kontakt_$( $processStart.toString("yyyyMMddHHmmss") ).csv"
        Write-Log "Uploading file to '$( $uploadKey )'"
        Write-S3Object @awsS3 -File $exportFile -Key $uploadKey -MetaData $metadata
    } else {
        Write-Log "The file contains 0 rows. No upload to S3."
    }


} catch {

    $msg = "Error during process"
    Write-Log -Message $msg -Severity ERROR #-WriteToHostToo $false
    Write-Log -Message $_.Exception -Severity ERROR
    throw $_

} finally {

    #-----------------------------------------------
    # STOP TIMER
    #-----------------------------------------------

    $processEnd = [datetime]::now
    $processDuration = New-TimeSpan -Start $processStart -End $processEnd
    Write-Log -Message "Needed $( [math]::floor([int]$processDuration.TotalSeconds) ) seconds in total" -severity INFO
            
    #Write-Log "Got $( $i ) rows. Uploaded $( $j ) records, $( $l ) failed." -severity INFO


    #-----------------------------------------------
    # REMOVE TEMP FOLDER
    #-----------------------------------------------

    Write-Log "Removing '$( $tempDir.FullName )'"
    #Remove-Item -Path $tempDir.FullName -Force -Recurse


    #-----------------------------------------------
    # CLOSE DATABASE CONNECTIONS
    #-----------------------------------------------

    #Close-DuckDBConnection

}

Exit 0
