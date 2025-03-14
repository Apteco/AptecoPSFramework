

function Add-BulkJob {

<#
    .SYNOPSIS
        Import or export data from/to Salesforce using the BULK API v2

    .DESCRIPTION

        This function uses the Salesforce BULK API v2 to query or ingest data from/into Salesforce.
        It can be easily used to import and export data.

    .PARAMETER Object
        The salesforce object to ingest data into

    .PARAMETER Operation
        One of the following operations when ingesting data: insert|delete|hardDelete|update|upsert

    .PARAMETER Query
        The SOQL query to run, not used for ingesting data

    .PARAMETER QueryOperation
        Either request the not deleted data or all data. Allowed values: query|queryAll

    .PARAMETER LineEnding
        Depends on the operating system that created the file for ingesting data
        Or that receives the data
        Allowed values are LF (Linux) and CRLF (Windows)

    .PARAMETER ColumnDelimiter
        Typical csv delimiters, allowed are: BACKQUOTE|CARET|COMMA|PIPE|SEMICOLON|TAB

    .PARAMETER ExternalIdFieldName
        Upserting records requires an external ID field on the object involved in the job

    .PARAMETER Path
        The file to be uploaded, this does not support splitting, so be aware to have this file < 150M after base64 encoding

    .PARAMETER CheckSeconds
        Check the job status every n seconds

    .PARAMETER MaxSecondsWait
        Maximum wait time for the job

    .PARAMETER DownloadFailures
        Switch to generally download failes into a temporary file

    .PARAMETER FailureFilename
        The file to write the file to, when $DownloadFailures is true and there are failures

    .PARAMETER DownloadSuccessful
        Switch to generally download successful items into a temporary file

    .PARAMETER SuccessfulFilename
        The file to write the file to, when $DownloadSuccessful is true and there are successful records

    .PARAMETER DownloadUnprocessed
        Switch to generally download unprocessed items into a temporary file

    .PARAMETER UnprocessedFilename
        The file to write the file to, when $DownloadUnprocessed is true and there are unprocessed records

    .EXAMPLE
        Get all IDs from an object and delete all records

        $tempFile = "c:\temp\tempfile.csv"
        $d = Invoke-SFSCQuery -Query "Select Id from CampaignMember" -bulk
        $l = $d | Select Id | convertto-csv -Delimiter "`t" -NoTypeInformation
        [IO.File]::WriteAllLines($tempFile, $l) # Write the file with BOM
        Add-BulkJob -Object CampaignMember -Operation delete -ColumnDelimiter TAB -LineEnding CRLF -Path $tempFile
        Invoke-SFSCQuery -Query "Select count() from CampaignMember"


    .EXAMPLE
        Building up job parameters and then execute the job.

        $successfulFilename =
        $lJobParams = [Hashtable]@{
            "Object" = "Lead"
            "Path" = "C:\temp\leads.csv"
            "Operation" = "upsert"
            "CheckSeconds" = 20
            "MaxSecondsWait" = 4000
            "DownloadSuccessful" = $True
            "SuccessfulFilename" = ( Join-Path -Path $Env:tmp -ChildPath "successful_$( [guid]::newguid().toString() ).csv" )
            "ExternalIdFieldName" = "apteco__externalId__c"
            "DownloadFailures" = $True
            "FailureFilename" = ( Join-Path -Path $Env:tmp -ChildPath "failed_$( [guid]::newguid().toString() ).csv" )
        }
        $lJob = Add-BulkJob @lJobParams


    .EXAMPLE
        Query data via bulk job

        $bulkParams = [Hashtable]@{
            "Query" = "Select id, name from Contact"
            "Path" = ".\newData.csv"
            "QueryOperation" = "query"
        }
        $return = Add-BulkJob @bulkParams

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        Array of jobs

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [CmdletBinding(DefaultParameterSetName = 'Ingest')]
    param (

        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$True, ParameterSetName = 'Ingest')]
         [String]$Object

        ,[Parameter(Mandatory=$True, ParameterSetName = 'Query')]
         [String]$Query

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [ValidateSet("insert", "delete", "hardDelete", "update", "upsert", IgnoreCase = $false)]
         [String]$Operation = "insert"             # insert|delete|hardDelete|update|upsert

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Query')]
         [ValidateSet("query","queryAll", IgnoreCase = $false)]
         [String]$QueryOperation = "query"             # query|queryAll

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [Parameter(Mandatory=$False, ParameterSetName = 'Query')]
         [ValidateSet("CRLF", "LF", IgnoreCase = $false)]
         [String]$LineEnding = "CRLF"             # LF (Linux) and CRLF (Windows)

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [Parameter(Mandatory=$False, ParameterSetName = 'Query')]
         [ValidateSet("BACKQUOTE", "CARET", "COMMA", "PIPE", "SEMICOLON", "TAB", IgnoreCase = $false)]
         [String]$ColumnDelimiter = "TAB"             # BACKQUOTE|CARET|COMMA|PIPE|SEMICOLON|TAB

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [String]$ExternalIdFieldName = ""

        # TODO implement splitting of multiple files and return an array of jobs rather than one job -> currently done in the calling script
        ,[Parameter(Mandatory=$True, ParameterSetName = 'Ingest')]
         [Parameter(Mandatory=$True, ParameterSetName = 'Query')]
         [String]$Path = ""

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [Parameter(Mandatory=$False, ParameterSetName = 'Query')]
         [Int]$CheckSeconds = 15

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [Parameter(Mandatory=$False, ParameterSetName = 'Query')]
         [Int]$MaxSecondsWait = 3000

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [Switch]$DownloadFailures = $false

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [String]$FailureFilename = ""

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [Switch]$DownloadSuccessful = $false

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [String]$SuccessfulFilename = ""

         ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [Switch]$DownloadUnprocessed = $false

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Ingest')]
         [String]$UnprocessedFilename = ""

    )

    begin {

        #-----------------------------------------------
        # NOTES
        #-----------------------------------------------

        <#

        #>

        #-----------------------------------------------
        # CHECK THE INPUT FILE
        #-----------------------------------------------

        # Resolve the filename to an absolute path
        $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)


        If ($PSCmdlet.ParameterSetName -eq "Ingest") {

            If ( ( Test-Path -Path $absolutePath -IsValid ) -eq $True ) {

                If ( ( Test-Path -Path $absolutePath ) -eq $True ) {
                    # path is valid
                } else {
                    throw "Path '$( $absolutePath )' is not existing"
                }

            } else {
                throw "Path '$( $absolutePath )' is not valid"
            }
        }


        #-----------------------------------------------
        # CHECK THE OUTPUT FILE
        #-----------------------------------------------

        If ($PSCmdlet.ParameterSetName -eq "Query") {

            # Check the filename
            If ( ( Test-Path -Path $absolutePath -IsValid -PathType Leaf ) -eq $True ) {
                # Filepath seems to be allowed
                #Split-path $p -Parent
            } else {
                throw "Path '$( $absolutePath )' is not valid"
            }

        }


        #-----------------------------------------------
        # CHECK THE FILES TO DOWNLOAD
        #-----------------------------------------------

        If ( $DownloadFailures -eq $True ) {

            # Create a default filename, if empty
            If ( $FailureFilename -eq "" ) {
                ".\failed_$( [guid]::newguid.ToString() )_$( [datetime]::now.toString("yyyyMMdd_HHmmss") ).csv"
            }

            # Resolve the filename to an absolute path
            $failAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FailureFilename)

            # Check the filename
            If ( ( Test-Path -Path $failAbsolutePath -IsValid -PathType Leaf ) -eq $True ) {
                # Filepath seems to be allowed
                #Split-path $p -Parent
            } else {
                throw "Path '$( $failAbsolutePath )' is not valid"
            }

        }

        If ( $DownloadSuccessful -eq $True ) {

            # Create a default filename, if empty
            If ( $SuccessfulFilename -eq "" ) {
                ".\successful_$( [guid]::newguid.ToString() )_$( [datetime]::now.toString("yyyyMMdd_HHmmss") ).csv"
            }

            # Resolve the filename to an absolute path
            $succAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SuccessfulFilename)

            # Check the filename
            If ( ( Test-Path -Path $succAbsolutePath -IsValid -PathType Leaf ) -eq $True ) {
                # Filepath seems to be allowed
                #Split-path $p -Parent
            } else {
                throw "Path '$( $succAbsolutePath )' is not valid"
            }

        }

        If ( $DownloadUnprocessed -eq $True ) {

            # Create a default filename, if empty
            If ( $UnprocesssedFilename -eq "" ) {
                ".\unprocesssed_$( [guid]::newguid.ToString() )_$( [datetime]::now.toString("yyyyMMdd_HHmmss") ).csv"
            }

            # Resolve the filename to an absolute path
            $unpAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($UnprocesssedFilename)

            # Check the filename
            If ( ( Test-Path -Path $unpAbsolutePath -IsValid -PathType Leaf ) -eq $True ) {
                # Filepath seems to be allowed
                #Split-path $p -Parent
            } else {
                throw "Path '$( $unpAbsolutePath )' is not valid"
            }

        }


        #-----------------------------------------------
        # SOME SETTINGS
        #-----------------------------------------------


    }

    process {

        #-----------------------------------------------
        # DEFINE DATA
        #-----------------------------------------------

        <#

        # COLUMN NAMES

        For a standard field, use the Field Name value as the field column header in your CSV file.
        For a custom field, use the API Name value as the field column header in a CSV file or the field name identifier in an XML or JSON file. (To find the API Name, click the field name.)

        # PARENT ENTRIES

        You can use a child-to-parent relationship, but you can't use a parent-to-child relationship.
        You can use a child-to-parent relationship, but you can't extend it to use a child-to-parent-grandparent relationship.
        You can only use indexed fields on the parent object. A custom field is indexed if its External ID field is selected. A standard field is indexed if its idLookup property is set to true. See the Field Properties column in the field table for each standard object.

        #>

        #-----------------------------------------------
        # CHECK INPUT FILES AND SPLIT THEM IF TOO BIG
        #-----------------------------------------------

        # TODO Split-File is already added to helpers, but implement it here and loop through everything
        <#

        To fulfill the maximum filesize of 150MB after base64 (enlarges around 33%), the file shouldn't be
        larger than 112 MB.

        A file with 4 columns with a width of 20 characters and TAB delimiter can contain around 1.2M rows.

        Do not forget that the failure files should also get an increment in their filename

        #>


        #-----------------------------------------------
        # CREATE JOB
        #-----------------------------------------------

        <#

        # REFERENCE

        https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/create_job.htm

        # EXTERNAL ID

        (Copied from the SF Help)

        Confirm that your object is using an external ID field.

        Upserting records requires an external ID field on the object involved in the job. Bulk API 2.0 uses the external ID field to determine whether a record is used to update an existing record or create a record.
        This example assumes that the external ID field customExtIdField__c has been added to the Account object.
        To add this custom field in your org with Object Manager, use these properties.

            Data Type—text
            Field Label—customExtIdField
            Select External ID

        #>

        switch ($PSCmdlet.ParameterSetName) {

            "Ingest" {

                $jobDetails = [PSCustomObject]@{
                    #"assignmentRuleId" = ""
                    "object" = $Object     # Single object per job
                    "contentType" = "CSV"           # CSV - No more options available
                    "operation" = $Operation          # insert|delete|hardDelete|update|upsert
                    "lineEnding" = $LineEnding         # LF (Linux) and CRLF (Windows)
                    "columnDelimiter" = $ColumnDelimiter     # BACKQUOTE|CARET|COMMA|PIPE|SEMICOLON|TAB
                }

                # Required for upsert, something like customExtIdField__c
                If ( $ExternalIdFieldName -ne "") {
                    $jobDetails | Add-Member -MemberType NoteProperty -Name "externalIdFieldName" -Value $ExternalIdFieldName
                }

                $job = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/" -Method "POST" -Body $jobDetails

                break
            }

            "Query" {

                $jobDetails = [PSCustomObject]@{
                    #"assignmentRuleId" = ""
                    "query" = $Query     # Single object per job
                    "contentType" = "CSV"           # CSV - No more options available
                    "operation" = $QueryOperation          # query|queryAll
                    "lineEnding" = $LineEnding         # LF (Linux) and CRLF (Windows)
                    "columnDelimiter" = $ColumnDelimiter     # BACKQUOTE|CARET|COMMA|PIPE|SEMICOLON|TAB
                }

                $job = Invoke-SFSC -Service "data" -Object "jobs" -Path "/query/" -Method "POST" -Body $jobDetails

            }

        }


        # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Content-Type: application/json" -H "Accept: application/json" -H "X-PrettyPrint:1" -d @newinsertjob.json -X POST
        #$jobDetailsJson = ConvertTo-Json $jobDetails
        #$job = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/" -Method POST -verbose -ContentType $contentType -Headers $headers -body $jobDetailsJson

        # ingest return
        <#

        { "id" : "7505fEXAMPLE4C2AAM",​
        "operation" : "insert",​
        "object" : "Account",​
        "createdById" : "0055fEXAMPLEtG4AAM",​
        "createdDate" : "2022-01-02T21:33:43.000+0000",​
        "systemModstamp" : "2022-01-02T21:33:43.000+0000",​
        "state" : "Open",​
        "concurrencyMode" : "Parallel",​
        "contentType" : "CSV",​
        "apiVersion" : 58.0,​
        "contentUrl" : "services/data/58.0/jobs/ingest/7505fEXAMPLE4C2AAM/batches",​
        "lineEnding" : "LF",​ "columnDelimiter" : "COMMA" }

        #>

        Write-Log "Created job with id '$( $job.id )'"


        #-----------------------------------------------
        # SAVE THE LAST JOB ID
        #-----------------------------------------------

        If ( $Script:variableCache.Keys -contains "last_jobid" ) {
            $Script:variableCache.last_jobid = $job.id
        } else {
            $Script:variableCache.Add("last_jobid", $job.id)
        }


        #-----------------------------------------------
        # UPLOAD THE DATA
        #-----------------------------------------------

        # MAX 150M after Base64 encoding
        # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/7505fEXAMPLE4C2AAM/batches/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Content-Type: text/csv" -H "Accept: application/json" -H "X-PrettyPrint:1" --data-binary @bulkinsert.csv -X PUT

        #$upload = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/batches/" -Method PUT -verbose -ContentType "text/csv" -Headers $headers -body $accountsCsv

        # TODO Switch to multipart upload for better performance

        If ($PSCmdlet.ParameterSetName -eq "Ingest") {

            $upload = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/batches/" -Method "PUT" -ContentType "text/csv" -InFile $Path #$file.FullName

            Write-Log "Did the upload for job '$( $job.id )'"

        }


        #-----------------------------------------------
        # SET STATE COMPLETE
        #-----------------------------------------------

        # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/7505fEXAMPLE4C2AAM/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Content-Type: application/json; charset=UTF-8" -H "Accept: application/json" -H "X-PrettyPrint:1" --data-raw '{ "state" : "UploadComplete" }' -X PATCH
        # $patchDetails = [PSCustomObject]@{
        #     "state" = "UploadComplete"
        # }
        # $patchedJob = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/" -Method PATCH -verbose -ContentType $contentType -Headers $headers -body $patchDetails

        If ($PSCmdlet.ParameterSetName -eq "Ingest") {

            $uploadCompleteBody = [PSCustomObject]@{
                "state" = "UploadComplete"
            }
            $patchedJob = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/" -Method "PATCH" -body $uploadCompleteBody

            Write-Log "Patched the job '$( $job.id )' to state 'UploadComplete'"

        }

        <#

        { "id" : "7505fEXAMPLE4C2AAM",​
        "operation" : "insert",​
        "object" : "Account",​
        "createdById" : "0055fEXAMPLEtG4AAM",​
        "createdDate" : "2022-01-02T21:33:43.000+0000",​
        "systemModstamp" : "2022-01-02T21:33:43.000+0000",​
        "state" : "UploadComplete",​
        "concurrencyMode" : "Parallel",​
        "contentType" : "CSV",​
        "apiVersion" : 58.0 }

        #>


        #-----------------------------------------------
        # CHECK JOB STATUS ASYNC
        #-----------------------------------------------

        # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/jobs/ingest/7505fEXAMPLE4C2AAM/ -H 'Authorization: Bearer 00DE0X0A0M0PeLE!AQcAQH0dMHEXAMPLEzmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1EXAMPLEDUkWe6H34r1AAwOR8B8fLEz6nEXAMPLE' -H "Accept: application/json" -H "X-PrettyPrint:1" -X GET
        $jobStartTs = [datetime]::now
        Do {

            Start-Sleep -seconds $CheckSeconds

            #$jobStatus = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/jobs/ingest/$( $job.id )/" -Method GET -verbose -ContentType $contentType -Headers $headers
            switch ($PSCmdlet.ParameterSetName) {

                "Ingest" {
                    $jobStatus = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/" -Method "GET"
                    break
                }

                "Query" {
                    $jobStatus = Invoke-SFSC -Service "data" -Object "jobs" -Path "/query/$( $job.id )/" -Method "GET"
                }

            }
            Write-Log "  Job status: $( $jobStatus.state ) - $( $jobStatus.numberRecordsProcessed ) records done - $( $jobStatus.numberRecordsFailed ) records failed" # TODO maybe remove this log
            #$jobStatus.state

            $jobTs = New-TimeSpan -Start $jobStartTs -End ( [datetime]::now )

        } Until ( @("Failed", "JobComplete", "Aborted") -contains $jobStatus.state -or $jobTs.TotalSeconds -gt $MaxSecondsWait )

        #$jobStatus | ConvertTo-Json | sc ".\jobstatus.json" -encoding UTF8

        If ( $jobStatus.state -ne "JobComplete" ) {
            Write-Log -Severity ERROR -Message "Job $( $job.id ) with status '$( $jobStatus.state )': '$( $jobStatus.errorMessage )'"
            throw "$( $jobStatus.errorMessage )"
        } else {
            Write-Log -Severity VERBOSE -Message "Job $( $job.id ) with status '$( $jobStatus.state )':"
            Write-Log -Severity VERBOSE -Message "  retries: $( $jobStatus.retries )"
            Write-Log -Severity VERBOSE -Message "  totalProcessingTime: $( $jobStatus.totalProcessingTime )"
        }

        <#

        {
            "id":  "750FS00000FLBJDYA5",
            "operation":  "delete",
            "object":  "CampaignMember",
            "createdById":  "005FS00000Jg9p2YAB",
            "createdDate":  "2025-03-04T17:48:37.000+0000",
            "systemModstamp":  "2025-03-04T17:48:41.000+0000",
            "state":  "Failed",
            "concurrencyMode":  "Parallel",
            "contentType":  "CSV",
            "apiVersion":  58.0,
            "jobType":  "V2Ingest",
            "lineEnding":  "CRLF",
            "columnDelimiter":  "TAB",
            "numberRecordsProcessed":  0,
            "numberRecordsFailed":  0,
            "retries":  0,
            "totalProcessingTime":  0,
            "apiActiveProcessingTime":  0,
            "apexProcessingTime":  0,
            "errorMessage":  "InvalidBatch : The \u0027delete\u0027 batch must contain only ids"
        }


        #>


        #-----------------------------------------------
        # GET RESULTS AND BUILD RETURN OBJECT
        #-----------------------------------------------

        #$jobResults = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/" -method get
        $processed = $jobStatus.numberRecordsProcessed
        $failed = $jobStatus.numberRecordsFailed
        $successful = $processed - $failed

        $returnHashtable = [Hashtable]@{
            "jobid" = $job.id
            "processed" = $processed
            "failed" = $failed
            "successful" = $successful
        }

        # Write the failed results into a file
        If ( $DownloadFailures -eq $True -and $failed -gt 0 ) {
            $fails = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/failedResults" -method get #-outfile $failAbsolutePath  #| Set-Content -Path $failAbsolutePath
            $fails | Export-Csv $failAbsolutePath -Encoding UTF8 -NoTypeInformation -Delimiter "`t"
            Write-Log "Written failures to '$( $failAbsolutePath )'" -severity VERBOSE
            $returnHashtable.add("failureFile", $failAbsolutePath)
            $returnHashtable.add("failureObj", $fails)
        }

        # Write the successful results into a file
        If ( $DownloadSuccessful -eq $True -and $successful -gt 0 ) {
            $succ = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/successfulResults" -method get #-outfile $succAbsolutePath #| Set-Content -Path $succAbsolutePath
            $succ | Export-Csv $succAbsolutePath -Encoding UTF8 -NoTypeInformation -Delimiter "`t"
            Write-Log "Written successful to '$( $succAbsolutePath )'" -severity VERBOSE
            $returnHashtable.add("successfulFile", $succAbsolutePath)
            $returnHashtable.add("successfulObj", $succ)
        }

        # Write the unprocessed restults into a file (only when canceled or aborted)
        If ( $DownloadUnprocessed -eq $True ) {
            $unp = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $job.id )/unprocessedRecords" -method get #-outfile $unpAbsolutePath #| Set-Content -Path $unpAbsolutePath
            $unp | Export-Csv $unpAbsolutePath -Encoding UTF8 -NoTypeInformation -Delimiter "`t"
            Write-Log "Written unprocessed to '$( $unpAbsolutePath )'" -severity VERBOSE
            $returnHashtable.add("unprocessedFile", $unpAbsolutePath)
            $returnHashtable.add("unProcessedObj", $unp)

        }

        # Download file via paging
        If ( $PSCmdlet.ParameterSetName -eq "Query") {
            # TODO [x] implement paging
            # TODO add maxRecords to Parameter or settings
            $data = Invoke-SFSC -Service "data" -Object "jobs" -Path "/query/$( $job.id )/results" -Query ( [PSCustomObject]@{ "maxRecords" = "50000" } ) -method get -headers ( [Hashtable]@{ "Accept-Encoding" = "gzip" } )
        }


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        If ( $PSCmdlet.ParameterSetName -eq "Query") {
            $data
        } else {
            [Array]@(
                $returnHashtable
            )
        }


    }

    end {

    }

}



