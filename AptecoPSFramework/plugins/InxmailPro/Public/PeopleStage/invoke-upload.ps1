﻿



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

        # Log the job in the database
        Set-JobLogDatabase
        $jobId = Add-JobLog

        $jobParams = [Hashtable]@{
            "JobId" = $jobId
            "Plugin" = $script:settings.plugin.guid
            "Input" = ( ConvertTo-Json $InputHashtable -Depth 99 )
            "Status" = "Starting"
            "DebugMode" = $Script:debugMode
            "Type" = $moduleName
        }
        Update-JobLog @jobParams


        #-----------------------------------------------
        # DEBUG MODE
        #-----------------------------------------------

        Write-Log "Debug Mode: $( $Script:debugMode )"


        #-----------------------------------------------
        # PARSE MESSAGE
        #-----------------------------------------------

        #$script:debug = $InputHashtable
        $isUploadOnly = $false

        If ( "" -eq $InputHashtable.MessageName ) {

            $isUploadOnly = $true
            $mailing = [Mailing]::new(999, "UploadOnly")

        } else {

            Write-Log "Parsing message: '$( $InputHashtable.MessageName )' with '$( $Script:settings.nameConcatChar )' as separator"
            $mailing = [Mailing]::new($InputHashtable.MessageName)
            Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"

            #$mailing = [Mailing]::new($InputHashtable.MessageName)
            #Write-Log "Got chosen message entry with id '$( $mailing.mailingId )' and name '$( $mailing.mailingName )'"

        }


        #-----------------------------------------------
        # DEFAULT VALUES
        #-----------------------------------------------

        $uploadSize = $Script:settings.upload.uploadSize
        Write-Log "Got UploadSize of $( $uploadSize ) rows/objects" #-Severity WARNING
        If ($uploadSize -gt 1000 ) {
            Write-Log "UploadSize has been set to more than 1000 rows. Using max of 1000 now!" -Severity WARNING
            $uploadSize = 1000
        }

        # Initiate row counter
        $i = 0  # row counter


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
        If ( $Script:settings.upload.countRowsInputFile -eq $true ) {
            $rowsCount = Measure-Rows -Path $file.FullName -SkipFirstRow
            Write-Log -Message "Got a file with $( $rowsCount ) rows"
            Update-JobLog -JobId $jobId -Inputrecords $rowsCount
        } else {
            Write-Log -Message "RowCount of input file not activated"
        }


        #-----------------------------------------------
        # CHECK INXMAIL CONNECTION
        #-----------------------------------------------

        try {

            Get-ApiUsage -ForceRefresh

        } catch {

            Write-Log -Message $_.Exception -Severity ERROR
            throw "Invalid connection"
            exit 0

        }

    }

    process {


        try {


            #-----------------------------------------------
            # CREATE GROUP IF NEEDED
            #-----------------------------------------------

            # If lists contains a concat character (id+name), use the list id
            # if no concat character is present, take the whole string as name for a new list and search for it... if not present -> new list!
            # if no list is present, just take the current date and time

            # If listname is valid -> contains an id, concatenation character and and a name -> use the id
            try {

                $createNewGroup = $false # No need for the group creation now
                $list = [MailingList]::new($InputHashtable.ListName)
                $listName = $list.mailingListName
                $groupId = $list.mailingListId
                Write-Log "Got chosen list/group entry with id '$( $list.mailingListId )' and name '$( $list.mailingListName )'"

                # Asking for details and possibly throw an exception
                $g = Invoke-CR -Object "groups" -Path "/$( $groupId )" -Method GET #-Verbose

            } catch {

                # Listname is the same as the message means nothing was entered -> check the name
                if ( $InputHashtable.ListName -ne $InputHashtable.MessageName ) {

                    # Try to search for that group and select the first matching entry or throw exception
                    $groups =  Invoke-CR -Object "groups" -Method "GET" #-Verbose

                    # Check how many matches are available
                    $matchingGroups = @( $groups | where-object { $_.name -eq $InputHashtable.ListName } ) # put an array around because when the return is one object, it will become a pscustomobject
                    switch ( $matchingGroups.Count ) {

                        # No match -> new group
                        0 {
                            $createNewGroup = $true
                            $listName = $InputHashtable.ListName
                            Write-Log -message "No matched group -> create a new one" -severity INFO
                        }

                        # One match -> use that one!
                        1 {
                            $createNewGroup = $false # No need for the group creation now
                            $listName = $matchingGroups.name
                            $groupId = $matchingGroups.id
                            Write-Log -message "Matched one group -> use that one" -severity INFO
                        }

                        # More than one match -> throw exception
                        Default {
                            $createNewGroup = $false # No need for the group creation now
                            Write-Log -message "More than one match -> throw exception" -severity ERROR
                            throw [System.IO.InvalidDataException] "More than two groups with that name. Please choose a unique list."
                        }
                    }

                # String is empty, create a generic group name
                } else {
                    $createNewGroup = $true
                    $listName = [datetime]::Now.ToString("yyyyMMdd_HHmmss")
                    Write-Log -message "Create a new group with a timestamp" -severity INFO
                }

            }

            # Create a new group (if needed)
            if ( $createNewGroup -eq $true ) {

                $body = [PSCustomObject]@{
                    "name" = "$( $listName )"
                }
                $newGroup = Invoke-CR -Object "groups" -Body $body -Method "POST" #-Verbose
                $groupId = $newGroup.id
                Write-Log -message "Created a new group with id $( $groupId )" -severity INFO

            }


            #-----------------------------------------------
            # GET GENERAL STATISTICS FOR LIST
            #-----------------------------------------------

            Write-Log "Getting stats for group $( $groupId )"

            #$groupStats = Invoke-CR -Object "groups" -Path "/$( $groupId )/stats" -Method GET -Verbose
            $groupStats = Get-GroupStats -GroupId $groupId

            <#
            {
                "total_count": 4,
                "inactive_count": 0,
                "active_count": 4,
                "bounce_count": 0,
                "avg_points": 69.5,
                "quality": 3,
                "time": 1685545449,
                "order_count": 0
            }
            #>

            $groupStats.psobject.properties | ForEach-Object {
                Write-Log "  $( $_.Name ): $( $_.Value )"
            }


            #-----------------------------------------------
            # LOAD HEADER AND FIRST ROWS
            #-----------------------------------------------

            # Read first 100 rows
            $deliveryFileHead = Get-Content -Path $file.FullName -TotalCount 201 -Encoding UTF8
            $deliveryFileCsv =  ConvertFrom-Csv $deliveryFileHead -Delimiter "`t"

            $headers = [Array]@( $deliveryFileCsv[0].psobject.properties.name )
            <#
            $headers | ForEach {

                $header = $_

                $sqliteParameterObject = $sqliteDeliveryInsertCommand.CreateParameter()
                $sqliteParameterObject.ParameterName = ":$( $header -replace '[^a-z0-9]', '' )"
                [void]$sqliteDeliveryInsertCommand.Parameters.Add($sqliteParameterObject)

                [void]$sqliteDeliveryCreateFields.Add( """$( $header )"" TEXT" )

            }#>

            $reservedFieldsCheck = Compare-Object -ReferenceObject $headers -DifferenceObject $Script:settings.upload.reservedFields -IncludeEqual
            If ( ( $reservedFieldsCheck | Where-Object { $_.SideIndicator -eq "==" } ).count -gt 0 ) {

                $msg = "You have used reserved fields:"
                Write-Log -Message $msg -Severity ERROR

                $reservedFieldsCheck | Where-Object { $_.SideIndicator -eq "==" } | ForEach-Object {
                    Write-Log -Message "  $( $_.InputObject )"
                }

                throw [System.IO.InvalidDataException] $msg
                exit 0

            }


            #-----------------------------------------------
            # CHECK ATTRIBUTES
            #-----------------------------------------------

            $requiredFields = @( $InputHashtable.EmailFieldName, $InputHashtable.UrnFieldName )
            $reservedFields = @( $Script:settings.upload.reservedFields ) #@("tags")
            Write-Log -message "Required fields: $( $requiredFields -join ", " )"
            Write-Log -message "Reserved fields: $( $reservedFields -join ", " )"

            $csvAttributesNames = $headers | Where-Object { $_.toLower() -notin $reservedFields }
            #$csvAttributesNames = Get-Member -InputObject $dataCsv[0] -MemberType NoteProperty | where { $_.Name -notin $reservedFields }
            Write-Log -message "Loaded csv attributes: $( $csvAttributesNames -join ", " )"

            $attributeParam = [Hashtable]@{
                "reservedFields" = $reservedFields  # TODO [ ] not used yet
                "requiredFields" = $requiredFields
                "csvAttributesNames" = $csvAttributesNames
                "csvUrnFieldname" = $InputHashtable.UrnFieldName
                "csvCommunicationKeyFieldName" = $InputHashtable.CommunicationKeyFieldName
                "responseUrnFieldname" = $Script:settings.responses.urnFieldName
                "groupId" = $groupId
            }

            # Logging attribute sync settings
            Write-Log "Attribute sync settings:"
            $attributeParam.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $attributeParam[$param] )'" #-writeToHostToo $false
            }

            $attributes = Sync-Attribute @attributeParam


            #-----------------------------------------------
            # GO THROUGH FILE IN PARTS
            #-----------------------------------------------

            <#
            
            NOTE

            Transform csv into compatible inxmail csv file (meaning that email field is in first place)

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
            
            #>

            $query = "select $( $params.EmailFieldName ) as email"


            #-----------------------------------------------
            # UPSERT DATA INTO LISTS
            #-----------------------------------------------

            # A certain method to correctly invoke
            $multipart = Prepare-MultipartUpload -string $csvString

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




            Write-Log "Stats for upload"
            Write-Log "  checked $( $i ) rows"
            Write-Log "  $( $v ) valid rows"
            Write-Log "  $( $j ) uploaded records"
            Write-Log "  $( $k ) uploaded batches"
            Write-Log "  $( $l ) failed records" # TODO log the failed entries somewhere? Or make an option for this?


            #-----------------------------------------------
            # GET GENERAL STATISTICS FOR LIST
            #-----------------------------------------------

            If ( $Script:settings.upload.loadRuntimeStatistics -eq $true ) {

                Write-Log "Getting stats for group $( $groupId )"

                #$groupStats = Invoke-CR -Object "groups" -Path "/$( $groupId )/stats" -Method GET -Verbose
                $groupStats = Get-GroupStatsByRuntime -GroupId $groupId #-IncludeMetrics -IncludeLastChanged -Verbose

                # <#
                # {
                #     "total_count": 4,
                #     "inactive_count": 0,
                #     "active_count": 4,
                #     "bounce_count": 0,
                #     "avg_points": 69.5,
                #     "quality": 3,
                #     "time": 1685545449,
                # }
                # #>

                $groupStats.psobject.properties | ForEach-Object {
                    Write-Log "  $( $_.Name ): $( $_.Value )"
                }

            }


        } catch {

            $msg = "Error during uploading data in code line $( $_.InvocationInfo.ScriptLineNumber ). Reached record $( $i ) Abort!"
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_.Exception


        } finally {


            # Close the file reader, if open
            # If the variable is not already declared, that shouldn't be a problem
            try {
                $reader.Close()
            } catch {

            }

            #-----------------------------------------------
            # STOP TIMER
            #-----------------------------------------------

            $processEnd = [datetime]::now
            $processDuration = New-TimeSpan -Start $processStart -End $processEnd
            Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"

            If ( $tags.length -gt 0 ) {
                Write-Log "Uploaded $( $j ) records, $( $l ) failed. Confirmed $( $tagcount ) receivers with tag '$( $tags )'" -severity INFO
            }

        }


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # count the number of successful upload rows
        $recipients = $check.successCount #$dataCsv.Count # TODO work out what to be saved

        # put in the source id as the listname
        $transactionId = $processId

        # return object
        $return = [Hashtable]@{

            # Mandatory return values
            "Recipients"=$recipients
            "TransactionId"=$transactionId

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $Script:settings.providername
            "ProcessId" = Get-ProcessId #$Script:processId

            # More values for broadcast
            "GroupId" = $groupId
            #"PreheaderIsSet" = $preheaderIsSet

        }

        # log the return object into logfile
        Write-Log -message "RETURN:"
        $return.Keys | ForEach-Object {
            $param = $_
            Write-Log -message "    $( $param ) = '$( $return[$param] )'" -writeToHostToo $false
        }

        # log the return into database and close connection
        $jobReturnParams = [Hashtable]@{
            "JobId" = $jobId
            "Status" = "Finished"
            "Finished" = $true
            "Successful" = $check.successCount
            "Failed" = 0 # TODO needs correction
            "Totalseconds" = $processDuration.TotalSeconds
            "Output" = ( ConvertTo-Json $return -Depth 99)
        }
        Update-JobLog @jobReturnParams
        Close-DuckDBConnection -Name "JobLog"

        # return the results
        $return


    }

    end {

    }

}



