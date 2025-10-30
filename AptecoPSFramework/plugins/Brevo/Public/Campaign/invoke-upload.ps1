

function Invoke-Upload {
    [CmdletBinding(DefaultParameterSetName = 'Object')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Object')]
        [Hashtable]$InputHashtable        # This creates a new entry in joblog
        
        ,[Parameter(Mandatory=$true, ParameterSetName = 'Job')]
        [Int]$JobId                          # This uses an existing joblog entry
        
        #[Parameter(Mandatory=$false)]
        #[Switch] $DebugMode = $false

    )
    
    begin {

        #-----------------------------------------------
        # MODULE INIT
        #-----------------------------------------------

        $moduleName = "UPLOAD"


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now

        write-log "Parameterset: $( $PSCmdlet.ParameterSetName )"


        #-----------------------------------------------
        # DEBUG MODE EVALUATION
        #-----------------------------------------------

        $debugMode = 0
        If ($PSBoundParameters["Debug"].IsPresent -eq $True) {
            If ($PSBoundParameters["Debug"] -eq $True) {
                $debugMode = 1
            }
        }


        #-----------------------------------------------
        # CHECK INPUT AND SET JOBLOG
        #-----------------------------------------------

        # Log the job in the database
        Set-JobLogDatabase
        Write-Log "Joblog database connected"

        Switch ( $PSCmdlet.ParameterSetName ) {

            "Object" {
                Write-log "adding a new job in function"

                # Create a new job
                $JobId = Add-JobLog
                $jobParams = [Hashtable]@{
                    "JobId" = $JobId
                    "Plugin" = $script:settings.plugin.guid
                    "InputParam" = $InputHashtable
                    "Status" = "Starting"
                    "DebugMode" = $debugMode #$Script:debugMode
                    "Type" = $moduleName
                }
                Update-JobLog @jobParams

                break
            }

            "Job" {
                Write-log "updating existing job"

                # Get the jobs information
                $job = Get-JobLog -JobId $JobId -ConvertInput
                $InputHashtable = $job.input

                # Update the job with more information
                $jobParams = [Hashtable]@{
                    "JobId" = $JobId
                    "Plugin" = $script:settings.plugin.guid
                    "Status" = "Starting"
                    "Type" = $moduleName
                }
                Update-JobLog @jobParams

                # Set the current process id
                Set-ProcessId -Id $job.process

                break
            }

        }


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

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
        # OPEN DEFAULT DUCKDB CONNECTION (NOT JOBLOG)
        #-----------------------------------------------

        Open-DuckDBConnection

        # Create the attributes table
        $attributesCreateStatementPath = Join-Path -Path $Script:moduleRoot -ChildPath "sql/attributes_create.sql"
        $attributesCreateStatement = Get-Content -Path $attributesCreateStatementPath -Encoding UTF8 -Raw
        Invoke-DuckDBQueryAsNonExecute -Query $attributesCreateStatement


        #-----------------------------------------------
        # PARSE MESSAGE
        #-----------------------------------------------

        #$script:debug = $InputHashtable
        $isUploadOnly = $false

        If ( "" -eq $InputHashtable.MessageName -and "" -ne $InputHashtable.ListName ) {
        
            Write-Log "Upload only mode activated, no message specified"
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
        <#
        $uploadSize = $Script:settings.upload.uploadSize
        Write-Log "Got UploadSize of $( $uploadSize ) rows/objects" #-Severity WARNING
        If ($uploadSize -gt 1000 ) {
            Write-Log "UploadSize has been set to more than 1000 rows. Using max of 1000 now!" -Severity WARNING
            $uploadSize = 1000
        }
        #>

        # Initiate row counter
        #$i = 0  # row counter


        #-----------------------------------------------
        # CHECK INPUT FILE
        #-----------------------------------------------

        # Checks input file automatically
        $file = Get-Item -Path $InputHashtable.Path
        Write-Log -Message "Got a file at '$( $file.FullName )'"

        # Add note in log file, that the file is a converted file
        if ( $file.FullName -match "\.converted$") {
            Write-Log -message "Be aware, that the exports are generated in Codepage 1252 and not UTF8. Please change this in the Channel Editor." -severity ( [LogSeverity]::WARNING )
        }

        # Count the rows
        If ( $Script:settings.upload.countRowsInputFile -eq $true ) {
            $rowsCount = Measure-Rows -Path $file.FullName -SkipFirstRow
            Write-Log -Message "Got a file with $( $rowsCount ) rows"
            Update-JobLog -JobId $JobId -Inputrecords $rowsCount
        } else {
            Write-Log -Message "RowCount of input file not activated"
        }

    }

    process {

        try {

            #-----------------------------------------------
            # CHECK FOLDER
            #-----------------------------------------------

            Write-Log "Checking for default folder for lists..."

            $defaultListFolderName = $Script:settings.upload.defaultListFolderName
            Write-Log -Message "Using default list folder name: $( $defaultListFolderName )"    

            $defaultListFolder = [Array]@( Get-Folder | Where-Object { $_.name -eq $defaultListFolderName } )

            If ( $defaultListFolder.Count -eq 0 ) {
                Write-Log -Message "  Default list folder '$( $defaultListFolderName )' not found. Creating it..." -Severity WARNING 
                $defaultListFolder = Add-Folder -Name $defaultListFolderName
                $defaultListFolderId = $defaultListFolder.id
            } else {
                Write-Log -Message "  Default list folder '$( $defaultListFolder.name )' found"
                $defaultListFolderId = $defaultListFolder[0].id
            }

        
            #-----------------------------------------------
            # CREATE GROUP IF NEEDED
            #-----------------------------------------------

            Write-Log "Checking for list..."

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
                $g = Get-List -Id $groupId #-Verbose

                If ( $g.name -ne $listName ) {
                    throw "List id and name do not match. Checking the creation of a new list."
                }

            } catch {

                # Listname is the same as the message means nothing was entered -> check the name
                if ( $InputHashtable.ListName -ne $InputHashtable.MessageName ) {

                    # Try to search for that group and select the first matching entry or throw exception
                    $groups =  Get-List -FolderId $defaultListFolderId -All #-Verbose

                    # Check how many matches are available
                    $matchingGroups = @( $groups | where-object { $_.name -eq $listName } ) # put an array around because when the return is one object, it will become a pscustomobject
                    switch ( $matchingGroups.Count ) {

                        # No match -> new group
                        0 {
                            $createNewGroup = $true
                            $listName = "$( $listName )#$([datetime]::Now.ToString("yyyyMMdd_HHmmss"))" #$InputHashtable.ListName
                            Write-Log -message "No matched group -> create a new one" #-severity INFO
                        }

                        # One match -> use that one!
                        1 {
                            $createNewGroup = $false # No need for the group creation now
                            $listName = $matchingGroups.name
                            $groupId = $matchingGroups.id
                            Write-Log -message "Matched one group -> use that one" #-severity INFO
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
                    $listName = "$( $listName )#$([datetime]::Now.ToString("yyyyMMdd_HHmmss"))"
                    Write-Log -message "Create a new group with a timestamp" #-severity INFO
                }

            }

            # Create a new group (if needed)
            if ( $createNewGroup -eq $true ) {

                $newGroup = Add-List -Name $listName -FolderId $defaultListFolderId
                
                $groupId = $newGroup.id
                Write-Log -message "Created a new group with id $( $groupId ) and name '$( $listName )'" #-severity INFO

            }


            #-----------------------------------------------
            # CHECK THE LIST SIZE
            #-----------------------------------------------

            $g = Get-List -Id $groupId
            If ( $createNewGroup -eq $True ) {
                $prefixList = "New"
            } else {
                $prefixList = "Existing"
            }
            Write-Log "$( $prefixList ) List '$( $g.name )' with id $( $g.id ) now contains $( $g.totalSubscribers ) subscribers" -severity INFO
            $listSizeBeforeUpload = $g.totalSubscribers


            #-----------------------------------------------
            # GET GENERAL STATISTICS FOR LIST
            #-----------------------------------------------

            # TODO Maybe needed later

            #Write-Log "Getting stats for group $( $groupId )"

            #$groupStats = Invoke-CR -Object "groups" -Path "/$( $groupId )/stats" -Method GET -Verbose
            #$groupStats = Get-GroupStats -GroupId $groupId

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

            #$groupStats.psobject.properties | ForEach-Object {
            #    Write-Log "  $( $_.Name ): $( $_.Value )"
            #}



            #-----------------------------------------------
            # LOAD CSV HEADERS/ATTRIBUTES
            #-----------------------------------------------

            Write-Log "Sniffing CSV input file for fields/attributes..."

            # Sniffing of first 1000 rows
            $sniff = Read-DuckDBQueryAsReader -Query "Select * from sniff_csv('$( $file.FullName )', $( $script:settings.upload.sniffparameter ))" -ReturnAsPSCustom

            # Write the columns into the database
            $sniff.Columns | ForEach-Object {
                $col = $_
                Invoke-DuckDBQueryAsNonExecute -Query "INSERT INTO attributes (name, type, source) VALUES ('$( $col.name )', '$( $col.type )', 'csv');"
                Write-Log "  $( $col.name ): $( $col.type )"
            }

            #$Script:pluginDebug = $sniff

            # Flag other important columns
            Invoke-DuckDBQueryAsNonExecute -Query "UPDATE attributes SET category = 'urn' WHERE name = '$( $InputHashtable.UrnFieldName )'"
            Invoke-DuckDBQueryAsNonExecute -Query "UPDATE attributes SET category = 'email' WHERE name = '$( $InputHashtable.EmailFieldName )'"
            Invoke-DuckDBQueryAsNonExecute -Query "UPDATE attributes SET category = 'mobile' WHERE name = '$( $InputHashtable.SmsFieldName )'"
            Invoke-DuckDBQueryAsNonExecute -Query "UPDATE attributes SET category = 'commkey' WHERE name = '$( $InputHashtable.CommunicationKeyFieldName )'"

            $urnFieldCount = Read-DuckDBQueryAsScalar -Query "SELECT count() FROM attributes where category = 'urn'"
            $emailFieldCount = Read-DuckDBQueryAsScalar -Query "SELECT count() FROM attributes where category = 'email'"
            #$mobileFieldCount = Read-DuckDBQueryAsScalar -Query "SELECT count() FROM attributes where category = 'mobile'"
            $commkeyFieldCount = Read-DuckDBQueryAsScalar -Query "SELECT count() FROM attributes where category = 'commkey'"


            Write-Log "Found fields in CSV for..."
            Write-Log "  URN: $( $urnFieldCount )"
            Write-Log "  email: $( $emailFieldCount )"
            #Write-Log "  mobile: $( $mobileFieldCount )"
            Write-Log "  communication key: $( $commkeyFieldCount )"

           
            #-----------------------------------------------
            # BREVO SPECIFIC CHANGES
            #-----------------------------------------------

            # Rename communication key columns
            $normalisedCommunicationKeyFieldName = "CommunicationKey" # TODO put to settings
            Invoke-DuckDBQueryAsNonExecute -Query "Update attributes SET name = trim(replace(name, ' ', '')) WHERE category = 'urn'"
            Invoke-DuckDBQueryAsNonExecute -Query "Update attributes SET name = '$( $normalisedCommunicationKeyFieldName )' WHERE category = 'commkey'"


            #-----------------------------------------------
            # CHECK FOR RESERVED FIELDS
            #-----------------------------------------------

            $reservedFields = @( $Script:settings.upload.reservedFields )

            If ( $reservedFields.Count -gt 0 ) {

                Write-Log "Checking for reserved fields: $( ( $reservedFields -join ',' ) )"
                
                $reservedFieldsCount = Read-DuckDBQueryAsScalar -Query "SELECT count() FROM attributes a where lower(trim(strip_accents(a.name))) in ('$( $reservedFields.trim().ToLower() -join "','")')"
                $reservedFieldsCount

            } else {

                Write-Log "No reserved fields in settings present"

            }


            #-----------------------------------------------
            # LOAD API ATTRIBUTES
            #-----------------------------------------------

            Write-Log "Loading global fields from API..."

            $attributes = Get-Attribute

            If ( $attributes.Count -gt 0 ) {
                $attributes | ForEach-Object {
                    $attr = $_
                    Invoke-DuckDBQueryAsNonExecute -Query "INSERT INTO attributes (name, type, source, scope) VALUES ('$( $attr.name )', '$( $attr.type )', 'api', 'global');"
                    #Write-Log "  $( $attr.name ): $( $attr.type )"
                }
            } else {
                Write-Log "  No global fields found"
            }

            $urnApiFieldCount = Read-DuckDBQueryAsScalar -Query "SELECT count() FROM attributes where lower(trim(strip_accents(name))) = lower(trim(strip_accents('$( $Script:settings.upload.urnFieldName.ToLower() )'))) AND source = 'api'"
            Write-Log "Found fields in API for..."
            Write-Log "  URN: $( $urnApiFieldCount )"
            

            #Write-Log "Loading local fields from API..."
            #Write-Log "  No local fields found"


            #-----------------------------------------------
            # JOIN ATTRIBUTES
            #-----------------------------------------------

            # TODO find out equivalent columns and check if new ones should be created
            #$q = "Select c.* from attributes c where source = 'csv' FULL OUTER JOIN attributes a on c.name = a.name WHERE a.source = 'api'"

            Write-Log "Result of column/field/attribute comparison"

            # Equivalent columns with local list
            $attributesEqualLocalSqlPath = Join-Path -Path $Script:pluginRoot -ChildPath "Sql/attributes_equal_local.sql"
            $attributesEqualLocalSql = Get-Content -Path $attributesEqualLocalSqlPath -Encoding UTF8 -Raw
            $attributesEqualLocal = [Array]@( Read-DuckDBQueryAsReader -Query $attributesEqualLocalSql -ReturnAsPSCustom )
            #Write-Log "  $( $attributesEqualLocal.count ) equal columns csv and local API list: $( $attributesEqualLocal.name -join ', ' )"

            # Equivalent columns with global list
            $attributesEqualGlobalSqlPath = Join-Path -Path $Script:pluginRoot -ChildPath "Sql/attributes_equal_global.sql"
            $attributesEqualGlobalSql = Get-Content -Path $attributesEqualGlobalSqlPath -Encoding UTF8 -Raw
            $attributesEqualGlobal = [Array]@( Read-DuckDBQueryAsReader -Query $attributesEqualGlobalSql -ReturnAsPSCustom )
            Write-Log "  $( $attributesEqualGlobal.count )  columns csv and global API list: $( $attributesEqualGlobal.name -join ', ' )"

            # Columns that are in CSV, but not in API
            $attributesInCsvNotApiSqlPath = Join-Path -Path $Script:pluginRoot -ChildPath "Sql/attributes_in_csv_not_in_api.sql"
            $attributesInCsvNotApiSql = Get-Content -Path $attributesInCsvNotApiSqlPath -Encoding UTF8 -Raw
            $attributesInCsvNotApi = [Array]@( Read-DuckDBQueryAsReader -Query $attributesInCsvNotApiSql -ReturnAsPSCustom )
            Write-Log "  $( $attributesInCsvNotApi.count ) CSV columns not in API: $( $attributesInCsvNotApi.name -join ', ' )"

            # Columns that are in API, but not in CSV
            $attributesInApiNotCsvSqlPath = Join-Path -Path $Script:pluginRoot -ChildPath "Sql/attributes_in_api_not_in_csv.sql"
            $attributesInApiNotCsvSql = Get-Content -Path $attributesInApiNotCsvSqlPath -Encoding UTF8 -Raw
            $attributesInApiNotCsv = [Array]@( Read-DuckDBQueryAsReader -Query $attributesInApiNotCsvSql -ReturnAsPSCustom )
            Write-Log "  $( $attributesInApiNotCsv.count ) API columns not in CSV: $( $attributesInApiNotCsv.name -join ', ' )"

            # Create a mapping of csv column name to API attribute name
            $columnMapping = [Ordered]@{}
            $columnMapping.Add($InputHashtable.UrnFieldName, $Script:settings.upload.urnFieldName.toUpper())
            $columnMapping.Add($InputHashtable.EmailFieldName, "EMAIL")
            #@( $attributesEqualLocal + $attributesEqualGlobal ) | Where-Object { $_.c_name -ne $InputHashtable.CommunicationKeyFieldName } | ForEach-Object {
                        #@( $attributesEqualLocal + $attributesEqualGlobal ) | Where-Object { $_.c_name -ne $InputHashtable.CommunicationKeyFieldName } | ForEach-Object {
            @( $attributesEqualLocal + $attributesEqualGlobal ) | ForEach-Object {
                $att = $_
                $columnMapping.Add($att.c_name, $att.name)
            }


            #-----------------------------------------------
            # CREATE ATTRIBUTES
            #-----------------------------------------------

            Write-Log "Check of attributes in API"

            # Checking URN field    
            If ( $urnApiFieldCount -eq 0 ) {
                Write-Log "  Creating URN field '$( $Script:settings.upload.urnFieldName )' in API"
                $newAttr = Add-Attribute -Name $Script:settings.upload.urnFieldName -Type "text"
                Write-Log "    Created new URN attribute with id $( $newAttr.id )"
            } elseif ( $urnFieldCount -eq 1 ) {
                Write-Log -Message "  URN field '$( $Script:settings.upload.urnFieldName )' found in API."
            } else {
                throw [System.IO.InvalidDataException] "More than one URN field found in API. Please correct this first." 
            }

            # Checking all other fields now
            If ( $Script:settings.upload.addNewAttributes -eq $True ) {

                If ( $attributesInCsvNotApi.Count -eq 0 ) {
                    Write-Log "No new attributes to be created in API"
                } else {
                    Write-Log "Creating new attributes in API..."
                }
                
                # Create new attributes in API
                $lookupAttributes = [System.Collections.ArrayList]@()
                $attributesInCsvNotApi | ForEach-Object {
                    $attr = $_
                    $type = "text" #$attr.type # TODO maybe do some conversion here
                    Write-Log "  Creating new attribute '$( $attr.normalised_name )' of type '$( $type )' in API"
                    $newAttr = Add-Attribute -Name $attr.normalised_name -Type $type
                    Write-Log "    Created new attribute with id $( $newAttr.id )"
                    $lookupAttributes.Add($attr.normalised_name) | Out-Null
                    #$columnMapping.Add($attr.name, $newAttr.name) # add to mapping too
                }

                Get-Attribute | Where-Object { $lookupAttributes -contains $_.name -and $_.name -ne $normalisedCommunicationKeyFieldName} | ForEach-Object {
                    $attr = $_
                    $attrKey = $lookupAttributes | Where-Object { $_.ToLower() -eq $attr.name.ToLower() }
                    $columnMapping.Add($attrKey, $attr.name) # add to mapping too
                }

            } else {

                Write-Log "Creation of new attributes in API is turned off"
                
            }


            #-----------------------------------------------
            # PREPARE UPLOAD
            #-----------------------------------------------

            # TODO put the statements into the settings

            # TODO do not forget to rename urn column and communication key column
            Invoke-DuckDBQueryAsNonExecute -Query "CREATE TABLE import AS SELECT * FROM read_csv('$( $file.FullName )', all_varchar = false, delim = '\t', encoding='utf-8', header = true);"
            $rowCount = Read-DuckDBQueryAsScalar -Query "SELECT count() FROM import"

            # We could transform the data here if needed
            $columnMapping.Add($InputHashtable.CommunicationKeyFieldName, $normalisedCommunicationKeyFieldName.ToUpper())

            # Now export the data again into a new file
            $tempFile = [System.IO.Path]::GetTempFileName()

            # parameter FILE_SIZE_BYTES could help to create partitioned files directly
            $exportColumns = [System.Text.StringBuilder]::new()
            $columnMapping.GetEnumerator() | ForEach-Object {
                $c = $_
                $exportColumns.Append("""$( $c.Name )"" AS ""$( $c.Value )""")
                if ( $c.Name -ne $columnMapping.GetEnumerator().Name[-1] ) {
                    $exportColumns.Append(", ")
                }
            }
            #, ""$( $InputHashtable.CommunicationKeyFieldName )"" as $( $normalisedCommunicationKeyFieldName ) EXCLUDE(""$( $InputHashtable.CommunicationKeyFieldName )"")
            
            Write-Log "Exporting data to temporary file '$( $tempFile )' with columns: $( $exportColumns.ToString() )"
            $resultFile = Read-DuckDBQueryAsReader -Query "COPY (SELECT $( $exportColumns.ToString() ) FROM import) TO '$( $tempFile )' (FORMAT CSV, DELIMITER ';', HEADER TRUE, QUOTE '');"
            Write-Log "File exported to '$( $tempFile )'"
            $Script:pluginDebug = $resultFile


            #-----------------------------------------------
            # DO UPLOAD
            #-----------------------------------------------

            Write-Log "Starting upload..."
            $import = Import-BrevoCsvContacts -FilePath $tempFile -ListId $groupId -DisableNotification $Script:settings.upload.DisableNotification -UpdateExistingContacts $True -EmptyContactsAttributes $Script:settings.upload.EmptyContactsAttributes #-Verbose
            Write-Log "Upload finished. Used $( $import.ImportProcesses.Count ) import processes:"
            $import.ImportProcesses | Group-Object Status | Sort-Object Count -Descending | ForEach-Object {
                $importStatus = $_
                Write-Log "  $( $importStatus.Count ) '$( $importStatus.Name )'"
            }


            #-----------------------------------------------
            # CHECK THE LIST SIZE
            #-----------------------------------------------

            $g = Get-List -Id $groupId 
            Write-Log "List '$( $g.name )' with id $( $g.id ) now contains $( $g.totalSubscribers ) subscribers"
            $listDifference = $g.totalSubscribers - $listSizeBeforeUpload
            $possiblyFailed = $rowCount - $listDifference
            Write-Log "Uploaded $( $listDifference ) new subscribers, possibly $( $possiblyFailed ) failed." -Severity INFO


            #-----------------------------------------------
            # LIST ERRORS
            #-----------------------------------------------

            Write-Log "Listing failed reasons..." #-Severity WARNING

            $import.Info.InvalidEmail | group-object Reason | Sort-Object Count -Descending | ForEach-Object {
                $failure = $_
                Write-Log "  $( $failure.Count ) '$( $failure.Name )'" -Severity WARNING
            }

            $import.Info.DuplicateContactId | group-object Reason | Sort Count -Descending | ForEach-Object {
                $failure = $_
                Write-Log "  $( $failure.Count ) '$( $failure.Name )'" -Severity WARNING
            }

            $import.Info.DuplicateExtId | group-object Reason | Sort-Object Count -Descending | ForEach-Object {
                $failure = $_
                Write-Log "  $( $failure.Count ) '$( $failure.Name )'" -Severity WARNING
            }

            $import.Info.DuplicateEmailId | group-object Reason | Sort-Object Count -Descending | ForEach-Object {
                $failure = $_
                Write-Log "  $( $failure.Count ) '$( $failure.Name )'" -Severity WARNING
            }

            
        } catch {

            $msg = "Error during uploading data in code line $( $_.InvocationInfo.ScriptLineNumber )."
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_


        } finally {


            # Close the file reader, if open
            # If the variable is not already declared, that shouldn't be a problem
            try {
                $reader.Close()
            } catch {

            }

            # Remove the temporary file, if existing
            If ( Test-Path -Path $tempFile ) {
                #Remove-Item -Path $tempFile -Force
                Write-Log "Removed temporary file '$( $tempFile )'"
            }


            #-----------------------------------------------
            # STOP TIMER
            #-----------------------------------------------

            $processEnd = [datetime]::now
            $processDuration = New-TimeSpan -Start $processStart -End $processEnd
            Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"

            #If ( $tags.length -gt 0 ) {
            #    Write-Log "Uploaded $( $j ) records, $( $l ) failed. Confirmed $( $tagcount ) receivers with tag '$( $tags )'" -severity INFO
            #}


            #-----------------------------------------------
            # CLOSE DEFAULT DUCKDB CONNECTION
            #-----------------------------------------------

            Close-DuckDBConnection

        }


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # count the number of successful upload rows
        $recipients = $listDifference

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
            "ReceiversTotal" = $recipients
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
            "JobId" = $JobId
            "Status" = "Finished"
            "Finished" = $true
            "Successful" = $recipients
            "Failed" = $possiblyFailed
            "Totalseconds" = $processDuration.TotalSeconds
            "OutputParam" = $return
        }
        Update-JobLog @jobReturnParams
        Close-JobLogDatabase

        # return the results
        Switch ( $PSCmdlet.ParameterSetName ) {
            "Object" {
                $return
                break
            }
            # Otherwise the results are now in the database
        }


    }

    end {

    }

}

