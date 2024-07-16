

function Get-Groups {

    [CmdletBinding(DefaultParameterSetName = 'Object')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName = 'Object')][Hashtable]$InputHashtable        # This creates a new entry in joblog
        ,[Parameter(Mandatory=$true, ParameterSetName = 'Job')][Int]$JobId                          # This uses an existing joblog entry
    )

    begin {


        #-----------------------------------------------
        # MODULE INIT
        #-----------------------------------------------

        $moduleName = "GROUPS"


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now

        write-log "Parameterset: $( $PSCmdlet.ParameterSetName )"


        #-----------------------------------------------
        # CHECK INPUT AND SET JOBLOG
        #-----------------------------------------------

        # Log the job in the database
        Set-JobLogDatabase

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
                    "DebugMode" = $Script:debugMode
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

        #Open-DuckDBConnection


    }

    process {

        $groups = Get-List -Type STANDARD
        Write-Log "Loaded $( $groups.Count ) groups from Inxmail" -severity INFO

        # Load and filter list into array of mailings objects
        $groupsList = [System.Collections.ArrayList]@()
        $groups | ForEach-Object {
            $group = $_
            [void]$groupsList.add(
                [MailingList]@{
                    mailingListId=$group.id
                    mailingListName=( $group.name -replace '[^\w\s]', '' )
                }
            )
        }

        # Transform the mailings array into the needed output format
        $columns = @(
            @{
                name="id"
                expression={ $_.mailingListId }
            }
            @{
                name="name"
                expression={ $_.toString() }
            }
        )

        $lists = [System.Collections.ArrayList]@()
        [void]$lists.AddRange(@( $groupsList | Select-Object $columns ))

        If ( $lists.count -gt 0 ) {

            Write-Log "Loaded $( $lists.Count ) lists/groups" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No lists loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw $msg

        }


        #-----------------------------------------------
        # STOP TIMER
        #-----------------------------------------------

        $processEnd = [datetime]::now
        $processDuration = New-TimeSpan -Start $processStart -End $processEnd
        Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"

        
        #-----------------------------------------------
        # CLOSE DEFAULT DUCKDB CONNECTION
        #-----------------------------------------------

        #Close-DuckDBConnection


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # log the return into database and close connection
        $jobReturnParams = [Hashtable]@{
            "JobId" = $JobId
            "Status" = "Finished"
            "Finished" = $true
            "Successful" = $lists.Count
            "Failed" = 0 # TODO needs correction
            "Totalseconds" = $processDuration.TotalSeconds
            "OutputArray" = $lists
        }
        Update-JobLog @jobReturnParams
        Close-JobLogDatabase


        # return the results
        Switch ( $PSCmdlet.ParameterSetName ) {
            "Object" {
                $lists
                break
            }
            # Otherwise the results are now in the database
        }

    }

    end {

    }

}

