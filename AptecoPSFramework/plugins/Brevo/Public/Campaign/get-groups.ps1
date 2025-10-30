

function Get-Groups {
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

        $moduleName = "GROUPS"


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

        # Load campaign member status data from Salesforce
        #$campaignMembers = @( Invoke-SFSCQuery -Query "Select Id, Label, CampaignId from CampaignMemberStatus where IsDeleted = false" )
        #$groups = $campaignMembers |  where-object { $_.CampaignId -ne "7010O000001CuXxQAK" } | group-object Label | Select-Object @{name="id";expression={ $lbyte=[System.Text.Encoding]::UTF8.GetBytes($_.Name);[Convert]::ToBase64String($lbyte) }}, Name
        $groups = Get-List -FolderId $Script:settings.upload.defaultListFolder -All
        
        Write-Log "Loaded $( $groups.Count ) status from Brevo" -severity INFO #-WriteToHostToo $false

        # Load and filter list into array of mailings objects
        $groupsList = [System.Collections.ArrayList]@()
        $groups | ForEach-Object {
            $group = $_
            [void]$groupsList.add(
                [MailingList]@{
                    "mailingListId" = $group.id #$group.Id.replace("=","") #Prefix 01Y0O00000 for status id, prefix 7010O000001 for campaign
                    "mailingListName" = $group.name
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

        $return = [System.Collections.ArrayList]@()
        [void]$return.AddRange(@( $groupsList | Select-Object $columns ))

        If ( $return.count -gt 0 ) {

            Write-Log "Loaded $( $return.Count ) lists/groups" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No lists loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

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
            "Successful" = $return.Count
            "Failed" = 0 # TODO needs correction
            "Totalseconds" = $processDuration.TotalSeconds
            "OutputArray" = $return
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

