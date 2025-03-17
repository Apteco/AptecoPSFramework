



function Invoke-Upload{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
    )

    begin {


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now
        #$inserts = 0


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "UPLOAD"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }


        #-----------------------------------------------
        # DEBUG MODE
        #-----------------------------------------------

        Write-Log "Debug Mode: $( $Script:debugMode )"


        #-----------------------------------------------
        # PARSE MESSAGE
        #-----------------------------------------------

        #$script:debug = $InputHashtable
        $uploadOnly = $false

        If ( "" -eq $InputHashtable.MessageName ) {

            $uploadOnly = $true
            $mailing = [Mailing]::new(999, "UploadOnly")

        } else {

            Write-Log "Parsing message: '$( $InputHashtable.MessageName )' with '$( $Script:settings.nameConcatChar )' as separator"
            $mailing = [Mailing]::new($InputHashtable.MessageName)
            Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"

        }


        #-----------------------------------------------
        # CHECK INPUT FILE
        #-----------------------------------------------

        # Checks input file automatically
        $file = Get-Item -Path $InputHashtable.Path
        Write-Log -Message "Got a file at $( $file.FullName )"

        # Add note in log file, that the file is a converted file
        if ( $file.FullName -match "\.converted$") {
            Write-Log -message "Be aware, that the exports are generated in Codepage 1252 and not UTF8. Please change this in the Channel Editor." -severity ( [LogSeverity]::WARNING )
        }

        # Count the rows
        $rowsCount = 0
        # if this needs to much performance, this is not needed
        If ( $Script:settings.upload.countRowsInputFile -eq $true ) {
            $rowsCount = Measure-Rows -Path $file.FullName -SkipFirstRow
            Write-Log -Message "Got a file with $( $rowsCount ) rows"
        } else {
            Write-Log -Message "RowCount of input file not activated"
        }


        #-----------------------------------------------
        # CHECK SALESFORCE CONNECTION
        #-----------------------------------------------

        try {

            #TODO Implement connection test

        } catch {

            Write-Log -Message $_.Exception -Severity ERROR
            throw [System.IO.InvalidDataException] $msg
            exit 0

        }

        #-----------------------------------------------
        # CHECK INPUT PARAMETERS AND DATA
        #-----------------------------------------------

        # Check if there is a source variable available, when using subcampaigns
        If ( $Script:settings.upload.uploadIntoSubCampaigns -eq $True ) {
            If ( $Script:settings.upload.segmentVariablename -ne "" -and $Script:settings.upload.segmentVariablename.length -gt 0 ) {
                # Check if the source variable is available
                $fileHeaders = ( get-content -Encoding utf8 -TotalCount 1 -Path $file.FullName ) -split "`t"
                If ( $fileHeaders -contains $Script:settings.upload.segmentVariablename ) {
                    Write-Log -Severity VERBOSE -Message "The segment variable '$( $Script:settings.upload.segmentVariablename )' is available. Proceeding..."
                } else {
                    Write-Log -Severity ERROR -Message "The segment variable '$( $Script:settings.upload.segmentVariablename )' is not present in the source file"
                    throw "The segment variable '$( $Script:settings.upload.segmentVariablename )' is not present in the source file"
                }
            } else {
                Write-Log -Severity ERROR -Message "You have to fill the segmentVariablename setting!"
                throw "You have to fill the segmentVariablename setting!"
            }
        }


        #-----------------------------------------------
        # VARIABLES
        #-----------------------------------------------

        $successful = 0
        $failed = 0
        $processed = 0

    }

    process {


        try {


            #-----------------------------------------------
            # CHECK CAMPAIGN
            #-----------------------------------------------

            $campaignId = $mailing.mailingId
            $campaign = @( Get-SFSCObjectData -Object "Campaign" -Fields "id", "name" -Where $Script:settings.upload.campaignFilter -limit 200 ) | where-object { $_.Id -like "*$( $campaignId )" } | Select-Object -first 1
            Write-Log "Using salesforce campaign '$( $campaign.Name )' with id '$( $campaign.id )'"


            #-----------------------------------------------
            # OUTPUT CURRENT API USAGE
            #-----------------------------------------------

            Write-Log "Current API Limit: $( $Script:variableCache.api_rate_limit )"


            #-----------------------------------------------
            # CHECK CAMPAIGN MEMBER STATUS
            #-----------------------------------------------

            $list = [MailingList]::new($InputHashtable.ListName)
            $listName = $list.mailingListName
            $listId = $list.mailingListId

            Write-Log "Using salesforce campaign member status '$( $listName )'"


            #-----------------------------------------------
            # TRANSFORM THE DATA
            #-----------------------------------------------

            # SF fields metadata
            $sfFields = Get-SFSCObjectField -Object "CampaignMember" | where-object { $_.createable -eq $True }
            $sfFieldsNames = $sfFields.Name

            # CSV fields metadata
            $urnFieldName = $InputHashtable.UrnFieldName
            $excludeColumns = $Script:settings.upload.reservedFields

            # Load subcampaigns, if needed
            If ( $Script:settings.upload.uploadIntoSubCampaigns -eq $True ) {

                $segmentFieldName = $Script:settings.upload.segmentVariablename
                Write-Log "Building segmens on variable '$( $segmentFieldName )'"

                # Load subcampaigns to the chosen one
                $subCampaignsTable = @( Get-SFSCObjectData -Object "Campaign" -Fields "id", "name" -Where "IsDeleted = false and Status = 'Planned' and ParentId = '$( $campaign.id )'" -limit 200 )

                # Create a fast searchable hashtable
                $subCampaigns = [Hashtable]@{}
                $subCampaignsTable | ForEach-Object {
                    $sc = $_
                    $subCampaigns.Add($sc.name, $sc.id)
                }

                Write-Log "Loaded $( $subCampaigns.Keys.Count ) subcampaigns"

            }

            <#

                # Another way to stream through files

                $arr = [System.Collections.ArrayList]@()
                $elapsed = [System.Diagnostics.Stopwatch]::StartNew() 

                # Open the text file from disk
                $reader = New-Object System.IO.StreamReader("c:\faststats\Publish\DB01\system\Deliveries\PowerShell_Sent ~ Sent_2a165893-f884-4e6b-b5d8-d031f628eaf2.txt")
                $columns = (Get-Content "c:\faststats\Publish\DB01\system\Deliveries\PowerShell_Sent ~ Sent_2a165893-f884-4e6b-b5d8-d031f628eaf2.txt" -First 1).Split("`t")
                $null = $reader.readLine()

                # Read in the data, line by line
                $i = 0
                while (($line = $reader.ReadLine()) -ne $null) {
                    $o = [ordered]@{}
                    $c = 0
                    foreach ($cell in $line.Split("`t") ) {
                        $o.add($columns[$c], $cell)
                        $c += 1
                    }
                    [void]$arr.Add([PSCustomObject]$o)
                    $i++; if (($i % 10000) -eq 0) { 
                        Write-Host "$i rows have been inserted in $($elapsed.Elapsed.ToString())."
                    } 
                } 

                # Clean Up
                $reader.Close(); $reader.Dispose()

            #>

            $newCsv = [System.Collections.ArrayList]@()             # This object are campaign members with contact id
            $leadCsv = [System.Collections.ArrayList]@()            # This object is for leads to be upserted
            $upsertedLeadCsv = [System.Collections.ArrayList]@()    # This object are leads with upserted sfids. First with the custom id, then overwritten with sf id and then merged with newcsv
            $c = 0
            $skippedLines = 0
            Import-csv -Delimiter "`t" -Path $file.FullName -Encoding UTF8 | ForEach-Object {

                $row = $_
                $campaignId = $null

                If ( $newCsv.Count -eq 0 ) {

                    $rowColumns = ( $row.psobject.properties | Where-Object { $_.name -notin $excludeColumns } ).name
                    Write-Log "Got the row columns: '$( $rowColumns -join "', '" )'"

                    $props = [System.Collections.ArrayList]@()
                    ForEach ( $prop in $rowColumns ) {
                        #$prop = $_
                        If ( $sfFieldsNames -contains $prop ) {
                            [void]$props.Add($prop)
                        }
                    }

                }

                # Check the (sub)campaign id
                If ( $Script:settings.upload.uploadIntoSubCampaigns -eq $True ) {
                    $segment = $row.$segmentFieldName
                    $subCampaignId = $subCampaigns[($subCampaigns.keys -like "*$( $segment )*")]
                    If ( $subCampaignId.Count -eq 1 ) {
                        $campaignId = $subCampaignId[0].toString()
                    }
                } else {
                    $campaignId = $campaign.id
                }

                # Check the id/urn first, if it is Salesforce
                If ( ( Test-SalesforceId $row.$urnFieldName ) -eq $True ) {

                    # THIS IS A CONTACT

                    # When campaign ID is found
                    If ( $null -ne $campaignId ) {

                        $line = [Ordered]@{
                            "CampaignID" = $campaignId
                            "Status" = $list.mailingListId
                            "ContactId" = $row.$urnFieldName
                            "LeadId" = ""
                        }
                        
                        ForEach ( $prop in $props ) {
                            $line.Add( $prop, $row.$prop )

                        }
                        [void]$newCsv.add([PSCustomObject]$line)
    
                    } else {
    
                        $skippedLines += 1
    
                    }

                    
                } else {

                    # THIS MEANS IT IS A LEAD, SO PREPARE THAT

                    # When campaign ID is found
                    If ( $null -ne $campaignId ) {

                        If ( $leadCsv.Count -eq 0 ) {

                            # Get Lead columns
                            $sfLeadFields = Get-SFSCObjectField -Object "Lead" | where-object { $_.createable -eq $True }
                            $sfLeadFieldsNames = $sfLeadFields.name
                            $externalLeadId = $Script:settings.upload.leadExternalId

                            $leadProps = [System.Collections.ArrayList]@()
                            ForEach ( $prop in $rowColumns ) {
                                If ( $sfLeadFieldsNames -contains $prop ) {
                                    [void]$leadProps.Add($prop)
                                }
                            }

                        }

                        # Create the line for the leads object
                        $leadLine = [Ordered]@{
                            $externalLeadId = $row.$urnFieldName
                        }
                        ForEach ( $prop in $leadProps ) {
                            $leadLine.Add( $prop, $row.$prop )
                        }
                        [void]$leadCsv.add([PSCustomObject]$leadLine)

                        # Create the line for the campaign members object
                        $line = [Ordered]@{
                            "CampaignID" = $campaignId
                            "Status" = $list.mailingListId
                            "ContactId" = ""
                            "LeadId" = $row.$urnFieldName
                        }
                        ForEach ( $prop in $props ) {
                            $line.Add( $prop, $row.$prop )
                        }
                        [void]$upsertedLeadCsv.add([PSCustomObject]$line)

                    } else {
    
                        $skippedLines += 1
    
                    }

                    
                }

                $c += 1

                If ( $c % 10000 -eq 0 ) {
                    Write-Log -Severity VERBOSE -Message "Checked $( $c ) lines"
                }

            }

            Write-Log "Stats after converting file"
            Write-Log "  Checked $( $c ) lines in total"
            Write-Log "  Converted $( $newCsv.count ) contacts lines"
            Write-Log "  Converted $( $leadCsv.count ) leads lines (not upserted yet)"
            Write-Log "  Skipped $( $skippedLines ) contacts/leads lines" # TODO should this trigger an error?

            # Checking the campaigns stats
            Write-Log -Severity VERBOSE -Message "Campaign summmary:"
            $newCsv | where-object { $_.ContactId -ne "" } | group-object CampaignID | Sort-Object Count -Descending | ForEach-Object {
                $c = $_
                Write-Log -Severity VERBOSE -Message "  $( $c.Name ): $( $c.Count ) contacts"
            }


            #-----------------------------------------------
            # CHECK LEADS
            #-----------------------------------------------
            
            If ( $leadCsv.Count -gt 0 ) {

                $leadCount = 0
                $skippedLines = 0
                
                # Create all files to upload
                Write-Log "Writing lead files"
                $leadFilesToUpload = [System.Collections.ArrayList]@()
                $batches = [math]::Ceiling( $leadCsv.Count / $Script:settings.upload.uploadSize )
                For ( $i = 0; $i -lt $batches; $i++ ) {

                    $start = $i * $Script:settings.upload.uploadSize
                    $end = $start + $Script:settings.upload.uploadSize -1

                    $lf = Join-Path -Path $Env:tmp -ChildPath "lead_$( $Script:processId )_$( $i ).csv" # TODO delete afterwards
                    $leadCsvContent = $leadCsv[$start..$end] | convertto-csv -NoTypeInformation -Delimiter "`t"
                    [IO.File]::WriteAllLines( $lf, $leadCsvContent )
                    [void]$leadFilesToUpload.Add( $lf )

                    Write-Log " Written file $( $i+1 ) to '$( $lf )'"

                    $currentSizeMB = [math]::Ceiling(( get-item -Path $lf ).length /[math]::Pow(2,20))
                    If ( $currentSizeMB -gt 110 ) {
                        throw "It looks like the output file is too large with $( $currentSizeMB ) MB"
                    }

                }

                Write-Log "$( $leadFilesToUpload.Count ) Lead files are written"
                Write-Log "Will do the upload in $( $leadFilesToUpload.Count ) batches with size of $( $Script:settings.upload.uploadSize ) records"

                # Upload all files
                $leadLookup = [Hashtable]@{}
                For ( $i = 0; $i -lt $leadFilesToUpload.Count; $i++ ) {

                    Write-Log "Starting with run $( $i ) and file '$( $leadFilesToUpload[$i] )'"

                    $successfulFilename = Join-Path -Path $Env:tmp -ChildPath "successful_$( [guid]::newguid().toString() )_$( $i ).csv"
                    $lJobParams = [Hashtable]@{
                        "Object" = "Lead"
                        "Path" = $leadFilesToUpload[$i]
                        "Operation" = "upsert"
                        "CheckSeconds" = $Script:settings.upload.checkSeconds
                        "MaxSecondsWait" = $Script:settings.upload.maximumWaitUntilJobFinished
                        "DownloadSuccessful" = $True
                        "SuccessfulFilename" = $successfulFilename
                        "ExternalIdFieldName" = $externalLeadId
                        "DownloadFailures" = $Script:settings.upload.downloadFailedResults
                        "FailureFilename" = ".\failedleads_$( $Script:processId )_$( [datetime]::now.toString("yyyyMMdd_HHmmss") )_$( $i ).csv"    
                    }
                    $lJob = Add-BulkJob @lJobParams

                    # Get all created lead IDs back
                    # Create a hashtable for externalid / sfleadid
                    $lJob.successfulObj | ForEach-Object {
                        $o = $_
                        $leadLookup.Add($o.$externalLeadId, $o."sf__Id")
                    }

                    # Output failures
                    Write-Log -Severity VERBOSE -Message "Failure summmary:"
                    $lJob.failureObj | Group-Object "sf__Error" | Sort-Object Count -Descending | ForEach-Object {
                        $fail = $_
                        Write-Log -Severity WARNING -Message "  $( $fail.Count ) Error '$( $fail.Name )'"
                    }

                }

                # Now rewrite the leads file for campaign members
                $upsertedLeadCsv | ForEach-Object {

                    $row = $_

                    $lid = $row."LeadId"

                    # Overwrite with salesforce id, otherwise skip it
                    $sfid = $leadLookup[$lid]
                    If ( $null -ne $sfid ) {

                        $row."LeadId" = $sfid
                        [void]$newCsv.Add( $row )

                        $leadCount += 1

                    } else {

                        # Skip this line
                        $skippedLines += 1

                    }
                                        
                }

                Write-Log "Stats after upserting leads file"
                Write-Log "  Added $( $leadCount ) leads lines"
                Write-Log "  Skipped another $( $skippedLines ) leads lines" # TODO should this trigger an error?

                Write-Log -Severity VERBOSE -Message "Campaign summmary:"
                $newCsv | where-object { $_.LeadID -ne "" } | group CampaignID | Sort-Object Count -Descending | ForEach-Object {
                    $c = $_
                    Write-Log -Severity VERBOSE -Message "  $( $c.Name ): $( $c.Count ) leads"
                }

            }

            
            #-----------------------------------------------
            # WRITE THE DATA FILE
            #-----------------------------------------------

            # Create all files to upload
            Write-Log "Writing campaign member files"
            $campaignMemberFilesToUpload = [System.Collections.ArrayList]@()
            $batches = [math]::Ceiling( $newCsv.Count / $Script:settings.upload.uploadSize )
            For ( $i = 0; $i -lt $batches; $i++ ) {

                $start = $i * $Script:settings.upload.uploadSize
                $end = $start + $Script:settings.upload.uploadSize -1

                $nf = Join-Path -Path $Env:tmp -ChildPath "cm_$( $Script:processId )_$( $i ).csv" # TODO delete afterwards
                $cmCsvContent = $newCsv[$start..$end] | Sort-Object CampaignID | convertto-csv -NoTypeInformation -Delimiter "`t" # TODO maybe do the sorting earlier?
                [IO.File]::WriteAllLines( $nf, $cmCsvContent )
                [void]$campaignMemberFilesToUpload.Add( $nf )

                Write-Log " Written file $( $i+1 ) to '$( $nf )'"

            }

            Write-Log "$( $campaignMemberFilesToUpload.Count ) CampaignMember files are written"
            Write-Log "Will do the upload in $( $batches ) batches with size of $( $Script:settings.upload.uploadSize )"


            #-----------------------------------------------
            # UPLOAD THE DATA
            #-----------------------------------------------

            $cmJobs = [System.Collections.ArrayList]@()
            For ( $j = 0; $j -lt $campaignMemberFilesToUpload.Count; $j++ ) {

                Write-Log "Starting with run $( $j ) and file '$( $campaignMemberFilesToUpload[$j] )'"

                $cmJobParams = [Hashtable]@{
                    "Object" = "CampaignMember"
                    "Path" = $campaignMemberFilesToUpload[$j]
                    "CheckSeconds" = $Script:settings.upload.checkSeconds # TOD0 [x] maybe put this into settings
                    "MaxSecondsWait" = $Script:settings.upload.maximumWaitUntilJobFinished
                    "DownloadFailures" = $Script:settings.upload.downloadFailedResults
                    "FailureFilename" = ".\failed_$( $Script:processId )_$( [datetime]::now.toString("yyyyMMdd_HHmmss") )_$( $j ).csv"
                    #"ExternalIdFieldName" = "ContactId"    # This does not work ;-)
                }
    
                If ( $InputHashtable.operation -ne "" ) {
    
                    Switch ( $InputHashtable.operation ) {
    
                        # TODO implement more operations
    
                        "delete" {
                            $cmJobParams.Add( "Operation", "delete" )
                        }
    
                        default {
                            $cmJobParams.Add( "Operation", "insert" )
                        }
    
                    }
    
                }
    
                [void]$cmJobs.Add((Add-BulkJob @cmJobParams))
    
            }


            #-----------------------------------------------
            # CHECK THE RESULTS
            #-----------------------------------------------

            # Count all numbers together and log them
            $cmJobs | ForEach-Object {

                $j = $_
                $successful += $j.successful
                $failed += $j.failed
                $processed += $j.processed

                Write-Log -Severity VERBOSE -Message "Job $( $j.jobid ): $( $j.processed ) processed, $( $j.successful ) successful, $( $j.failed ) failed "

                If ( $j.failed -gt 0 ) {

                    $j.failureObj | Group-Object "sf__Error" | Sort-Object Count -Descending | ForEach-Object {
                        $fail = $_
                        Write-Log -Severity WARNING -Message "  $( $fail.Count ) Error '$( $fail.Name )'"
                    }

                }

            }

            #-----------------------------------------------
            # CHECK IF IT SHOULD ERROR
            #-----------------------------------------------

            Write-Log "$( $processed ) total processed records" -severity INFO
            Write-Log "$( $failed ) total failed" -severity INFO

            If ( $processed -gt 0 ) {
                $errorRate = $failed / $processed * 100
                If ( $errorRate -ge $Script:settings.upload.errorThreshold ) {
                    throw "There has been a problem with $( $errorRate )% error rate. There are more than $( $Script:settings.upload.errorThreshold )% errors."
                }
            }
            

        } catch {

            Write-Log -Message "Trying to get the failures of last job" -Severity WARNING
            If ( $Script:variableCache.Keys -contains "last_jobid" ) {
                $failures = Invoke-SFSC -Service "data" -Object "jobs" -Path "/ingest/$( $Script:variableCache.last_jobid )/failedResults"
                $failures | Group-Object "sf__Error" | Sort-Object Count -Descending | ForEach-Object {
                    $fail = $_
                    Write-Log -Severity ERROR -Message "  $( $fail.Count ) Error '$( $fail.Name )'"
                }
            }

            $msg = "Error during uploading data. Abort!"
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR

            throw $_.Exception

        } finally {

            <#
            # Delete created files
            If ( Test-Path $nf ) {
                #Remove-item -Path $nf # TODO take that back in
            }
            If ( Test-Path $lf ) {
                #$lf
            }
            If ( Test-Path $successfulFilename ) {
                #$successfulFilename 
            }
            #>

            #-----------------------------------------------
            # OUTPUT CURRENT API USAGE
            #-----------------------------------------------

            Write-Log "Current API Limit: $( $Script:variableCache.api_rate_limit )"


            #-----------------------------------------------
            # STOP TIMER
            #-----------------------------------------------

            $processEnd = [datetime]::now
            $processDuration = New-TimeSpan -Start $processStart -End $processEnd
            Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"

        }


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # count the number of successful upload rows
        $recipients = $successful

        # there could be multiple jobs per upload, so better using the guid here
        $transactionId = $Script:processId

        # return object
        $return = [Hashtable]@{

            # Mandatory return values
            "Recipients"=$recipients
            "TransactionId"=$transactionId

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $Script:settings.providername
            "ProcessId" = $Script:processId

            # More information about the different status of the import
            "RecipientsProcessed" = $processed
            "RecipientsFailed" = $failed
            "RecipientsSuccessful" = $successful

        }

        # log the return object
        Write-Log -message "RETURN:"
        $return.Keys | ForEach-Object {
            $param = $_
            Write-Log -message "    $( $param ) = '$( $return[$param] )'" -writeToHostToo $false
        }

        # return the results
        $return


    }

    end {

    }

}




