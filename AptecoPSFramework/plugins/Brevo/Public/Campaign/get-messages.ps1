

function Get-Messages {
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

        $moduleName = "MESSAGES"


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
        
        Switch ( $PSCmdlet.ParameterSetName ) {

            "Object" {

                # To save performance this can be skipped from the boilerplate files, but only when Paramatertype Object is used
                If ( $Env:SkipJobLog -eq $true ) {

                    Write-Log "Skipping JobLog"
                
                } else {

                    # Log the job in the database
                    Set-JobLogDatabase
                    Write-Log "Joblog database connected"

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

                
            }

            "Job" {

                # Log the job in the database
                Set-JobLogDatabase
                Write-Log "Joblog database connected"

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

        #Switch ( $InputHashtable.mode ) {

            #default {

                # Load mailings data from Brevo
                $campaigns = Get-Template -TemplateStatus "active" -All

                Write-Log "Loaded $( $campaigns.Count ) campaigns from Brevo" -severity INFO #-WriteToHostToo $false

                # Load and filter list into array of mailings objects
                $mailingsList = [System.Collections.ArrayList]@()
                $campaigns | ForEach-Object {
                    $mailing = $_
                    $maxLength = $mailing.Name.length
                    If ($maxLength -lt 20) {
                        $l = $maxLength
                    } else {
                        $l = 20
                    }
                    [void]$mailingsList.add(
                        [Mailing]@{
                            "mailingId" = $mailing.Id #.substring(11)
                            "mailingName" = $mailing.Name #.substring(0,$l)
                        }
                    )
                }

            #}

        #}


        # fields, id, name, status, type, StartDate, EndDate, ...
        # Get-SFSCObjectField -object "Campaign" | Out-GridView

        # Transform the mailings array into the needed output format
        $columns = @(
            @{
                name="id"
                expression={ $_.mailingId }
            }
            @{
                name="name"
                expression={ $_.toString() }
            }
        )

        $return = [System.Collections.ArrayList]@()
        [void]$return.AddRange(@( $mailingsList | Select-Object $columns ))

        If ( $return.count -gt 0 ) {

            Write-Log "Loaded $( $return.Count ) messages" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No messages loaded -> please check!"
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

        # To save performance this can be skipped from the boilerplate files, but only when Paramatertype Object is used
        If ( $Env:SkipJobLog -eq $true -and $PSCmdlet.ParameterSetName -eq "Object" ) {
            Write-Log "Skipping return infos into JobLog"
        } else {
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
        }

        # return the results
        Switch ( $PSCmdlet.ParameterSetName ) {
            "Object" {
                $return
                break
            }
            # Otherwise the results are now in the database
        }

    }

}

