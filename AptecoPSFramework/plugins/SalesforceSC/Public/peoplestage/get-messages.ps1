

function Get-Messages {
    [CmdletBinding(DefaultParameterSetName = 'Object')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName = 'Object')][Hashtable]$InputHashtable        # This creates a new entry in joblog
        ,[Parameter(Mandatory=$true, ParameterSetName = 'Job')][Int]$JobId                          # This uses an existing joblog entry
    )

    begin {


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "GETMESSAGES"

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

        If ( $PSBoundParameters["Debug"].IsPresent -eq $true ) {
            Write-Log -message "Debug mode: on"
        } else {
            Write-Log -message "Debug mode: off"
        }


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
        # DEPENDENCIES
        #-----------------------------------------------

        #Import-Module MeasureRows
        #Import-Lib -IgnorePackageStructure

    }

    process {

        #Switch ( $InputHashtable.mode ) {

            #default {

                # Load mailings data from SalesForce
                $campaigns = @( Get-SFSCObjectData -Object "Campaign" -Fields "id", "name" -Where $Script:settings.upload.campaignFilter -limit 200 )
                Write-Log "Loaded $( $campaigns.Count ) campaigns from Salesforce" -severity INFO #-WriteToHostToo $false

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
                            "mailingId" = $mailing.Id.substring(7,11)
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

        $messages = [System.Collections.ArrayList]@()
        [void]$messages.AddRange(@( $mailingsList | Select-Object $columns ))

        If ( $messages.count -gt 0 ) {

            Write-Log "Loaded $( $messages.Count ) messages" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No messages loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

        }

        # Return
        #$messages

        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # log the return into database and close connection
        $jobReturnParams = [Hashtable]@{
            "JobId" = $JobId
            "Status" = "Finished"
            "Finished" = $true
            "Successful" = $messages.Count
            "Failed" = 0 # TODO needs correction
            "Totalseconds" = $processDuration.TotalSeconds
            "OutputArray" = $messages
        }
        Update-JobLog @jobReturnParams
        Close-JobLogDatabase


        # return the results
        Switch ( $PSCmdlet.ParameterSetName ) {
            "Object" {
                $messages
                break
            }
            # Otherwise the results are now in the database
        }


    }

    end {

    }

}

