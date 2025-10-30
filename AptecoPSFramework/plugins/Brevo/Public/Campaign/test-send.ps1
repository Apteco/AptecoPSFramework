

function Test-Send {
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

        $moduleName = "TESTSEND"


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

        #Open-DuckDBConnection


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


        #-----------------------------------------------
        # CHECK INPUT FILE
        #-----------------------------------------------


    }

    process {

        try {


            
        

            # TODO Upload data to test list beforehand

            $params = [Hashtable]@{
                "Object" = "emailCampaigns"
                "Method" = "POST"
                "Path" = "$( $campaignId )/sendTest"
                "Body" = [PSCustomObject]$campaignBody
            }

            # add verbose flag, if set
            If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
                $params.Add("Verbose", $true)
            }
            $campaign = Invoke-Brevo @params

            

            
        } catch {

            $msg = "Error during uploading data in code line $( $_.InvocationInfo.ScriptLineNumber ). Reached record $( $i ) Abort!"
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_


        } finally {


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
        $recipients = $listDifference # TODO check out how to get the number of successful recipients

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
        Close-JobLogDatabase -Name "JobLog"

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

