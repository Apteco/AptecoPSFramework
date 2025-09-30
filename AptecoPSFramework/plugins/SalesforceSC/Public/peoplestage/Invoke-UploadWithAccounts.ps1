



function Invoke-UploadWithAccounts {

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

        If ( $Script:settings.upload.usePersonAccounts -eq $True ) {

            $fileHeaders = ( get-content -Encoding utf8 -TotalCount 1 -Path $file.FullName ) -split "`t" # When we have double quotes in the header, this will not work

            If ( $Script:settings.upload.personContactIdVariablename -ne "" -and $Script:settings.upload.personContactIdVariablename.length -gt 0 ) {
                # Check if the source variable is available
                If ( $fileHeaders -contains $Script:settings.upload.personContactIdVariablename ) {
                    Write-Log -Severity VERBOSE -Message "The personContactIdVariablename variable '$( $Script:settings.upload.personContactIdVariablename )' is available. Proceeding..."
                } else {
                    Write-Log -Severity ERROR -Message "The personContactIdVariablename variable '$( $Script:settings.upload.personContactIdVariablename )' is not present in the source file"
                    throw "The personContactIdVariablename variable '$( $Script:settings.upload.personContactIdVariablename )' is not present in the source file"
                }
            } else {
                Write-Log -Severity ERROR -Message "You have to fill the personContactIdVariablename setting!"
                throw "You have to fill the personContactIdVariablename setting!"
            }

            If ( $Script:settings.upload.isPersonAccountVariablename -ne "" -and $Script:settings.upload.isPersonAccountVariablename.length -gt 0 ) {
                # Check if the source variable is available
                If ( $fileHeaders -contains $Script:settings.upload.isPersonAccountVariablename ) {
                    Write-Log -Severity VERBOSE -Message "The isPersonAccountVariablename variable '$( $Script:settings.upload.isPersonAccountVariablename )' is available. Proceeding..."
                } else {
                    Write-Log -Severity ERROR -Message "The isPersonAccountVariablename variable '$( $Script:settings.upload.isPersonAccountVariablename )' is not present in the source file"
                    throw "The isPersonAccountVariablename variable '$( $Script:settings.upload.isPersonAccountVariablename )' is not present in the source file"
                }
            } else {
                Write-Log -Severity ERROR -Message "You have to fill the isPersonAccountVariablename setting!"
                throw "You have to fill the isPersonAccountVariablename setting!"
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
            # CHECK SUBCAMPAIGNS
            #-----------------------------------------------

            If ( $Script:settings.upload.useDatedSubCampaigns -eq $True ) {
                $createSubCampaign = $True
            } else {
                # Load subcampaigns to the chosen one
                $subCampaignsTable = @( Get-SFSCObjectData -Object "Campaign" -Fields "id", "name" -Where "IsDeleted = false and Status = 'Planned' and ParentId = '$( $campaign.id )' and name like '%$( $Script:settings.upload.subCampaignIdentifier )%' order by LastModifiedDate desc" -limit 1000 )

                # Regular expression to match the date format YYYYMMDD_HHMMSS
                $pattern = '\d{8}_\d{6}$'

                # Check if there are subcampaigns with the date in the name
                If ( $subCampaignsTable.Count -gt 0 ) {
                    $foundSubCampaign = $False
                    Write-Log "Found $( $subCampaignsTable.Count ) subcampaigns. Checking for ones without date in the name, using the first one"
                    $subCampaignsTable | where-object { $_.Name -notmatch $pattern } | ForEach-Object {
                        $sc = $_
                        Write-Log "  Subcampaign '$( $sc.Name )' with id '$( $sc.id )' matches"
                        If ( $foundSubCampaign -eq $False ) {
                            $subCampaign = $sc
                            Write-Log "  Using subcampaign '$( $subCampaign.Name )' with id '$( $subCampaign.id )'"
                            $foundSubCampaign = $True
                            $createSubCampaign = $false
                        }
                    }

                    If ( $foundSubCampaign -eq $False ) {
                        Write-Log "No subcampaigns found"
                        $createSubCampaign = $True
                    }

                } else {
                    Write-Log "No subcampaigns found"
                    $createSubCampaign = $True
                }
            }


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
            # BEFORE UPLOAD DO DOWNLOAD ALL VALID ID'S
            #-----------------------------------------------

            <#
            # The variable names are not final yet
            # Those are just outlines if we want to implement this check in the future

            # That setting does not exist yet
            If ($Script:settings.upload.checkValidIds -eq $true) {

                $arr = [System.Collections.ArrayList]@()
                # Get all valid account id's
                $a = Get-SFSCObjectData -Object Account -Fields Id, PersonContactId, IsPersonAccount -Where "IsDeleted = false" -limit -1 -Bulk

                # Add the account id's to the array
                $arr.AddRange($a.Id)

                # Add the person account id's to the array
                $arr.AddRange(($a | Where-Object { $_.IsPersonAccount -eq $True } ).PersonContactId)

                # Later just check if the id is in the array
                #$arr.Contains("003KB000005jr7GYAQ")

            }

            #>


            #-----------------------------------------------
            # TRANSFORM THE DATA
            #-----------------------------------------------

            # SF fields metadata
            $sfFields = Get-SFSCObjectField -Object "CampaignMember" | where-object { $_.createable -eq $True }
            $sfFieldsNames = $sfFields.Name

            # CSV fields metadata
            $urnFieldName = $InputHashtable.UrnFieldName
            $isPersonAccountVariablename = $Script:settings.upload.isPersonAccountVariablename
            $personContactIdVariablename = $Script:settings.upload.personContactIdVariablename
            $excludeColumns = $Script:settings.upload.reservedFields

            # Add a new subcampaign or use an existing one
            If ( $createSubCampaign -eq $True ) {

                If ( $Script:settings.upload.useDatedSubCampaigns -eq $True ) {
                    # Create a new subcampaign with the current date
                    $subCampaignName = "$(  $campaign.Name ) - $( $Script:settings.upload.subCampaignIdentifier ) - $( [datetime]::now.ToString("yyyyMMdd_HHmmss") )"
                } else {
                    # Create a new subcampaign without the current date
                    $subCampaignName = "$(  $campaign.Name ) - $( $Script:settings.upload.subCampaignIdentifier )"
                }

                # Set the campaignType
                If ( $InputHashtable.Keys -contains "CampaignType" ) {
                    If ( $InputHashtable.CampaignType -ne "" ) {
                        $campaignType = $InputHashtable.CampaignType
                    } else {
                        $campaignType = $Script:settings.upload.defaultCampaignType
                    }
                } else {
                    $campaignType = $Script:settings.upload.defaultCampaignType
                }

                # Add a new subcampaign
                $campaign = [PSCustomObject]@{
                    "Name" = $subCampaignName # TODO add a switch to append datetime or use an existing one
                    "Type" = $campaignType
                    "ParentId" = $campaign.id
                }
                $subCampaign = Add-SFSCObjectData -Object "Campaign" -Attributes $campaign

            }

            # Import the file and go through the lines
            $newCsv = [System.Collections.ArrayList]@()             # This object are campaign members with contact id
            $c = 0
            $skippedLines = 0
            Import-csv -Delimiter "`t" -Path $file.FullName -Encoding UTF8 | ForEach-Object {

                $row = $_
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

                # Check the id/urn first, if it is Salesforce
                If ( ( Test-SalesforceId $row.$urnFieldName ) -eq $True ) {

                    # Check if the contact is a person account
                    If ( $row.$isPersonAccountVariablename -eq "True" -or $row.$isPersonAccountVariablename -eq "true" ) {

                        # This is a person account
                        $line = [Ordered]@{
                            "CampaignID" = $subCampaign.id
                            "Status" = $list.mailingListId
                            "AccountId" = ""
                            "ContactId" = $row.$personContactIdVariablename
                        }

                    } else {

                        # This is an account
                        $line = [Ordered]@{
                            "CampaignID" = $subCampaign.id
                            "Status" = $list.mailingListId
                            "AccountId" = $row.$urnFieldName
                            "ContactId" = ""
                        }

                    }

                    ForEach ( $prop in $props ) {
                        $line.Add( $prop, $row.$prop )

                    }

                    [void]$newCsv.add([PSCustomObject]$line)

                } else {

                    # Just skip this line
                    $skippedLines += 1

                }

                $c += 1

                If ( $c % 10000 -eq 0 ) {
                    Write-Log -Severity VERBOSE -Message "Checked $( $c ) lines"
                }

            }

            Write-Log "Stats after converting file"
            Write-Log "  Checked $( $c ) lines in total"
            Write-Log "  Converted $( $newCsv.count ) accounts lines"
            Write-Log "  Skipped $( $skippedLines ) accounts lines" # TODO should this trigger an error?

            # Checking the campaigns stats
            # Write-Log -Severity VERBOSE -Message "Campaign summmary:"
            # $newCsv | where-object { $_.ContactId -ne "" } | group-object CampaignID | Sort-Object Count -Descending | ForEach-Object {
            #     $c = $_
            #     Write-Log -Severity VERBOSE -Message "  $( $c.Name ): $( $c.Count ) contacts"
            # }


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

                $tmpdir = Get-TemporaryPath
                $nf = Join-Path -Path $tmpdir -ChildPath "cm_$( $Script:processId )_$( $i ).csv" # TODO delete afterwards
                $cmCsvContent = $newCsv[$start..$end] | convertto-csv -NoTypeInformation -Delimiter "`t" # skipped the sorting by campaign id here as in other processes
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




