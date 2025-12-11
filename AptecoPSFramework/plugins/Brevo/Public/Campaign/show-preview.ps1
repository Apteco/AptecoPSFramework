

function Show-Preview {

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

        $moduleName = "PREVIEW"


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


    }

    process {

        try {

            
            #-----------------------------------------------
            # PARSE RECEIVER
            #-----------------------------------------------

            # Parse recipient
            $testRecipient = Convertfrom-Json -InputObject $InputHashtable.TestRecipient



            #-----------------------------------------------
            # LOAD API ATTRIBUTES
            #-----------------------------------------------

            Write-Log "Loading global fields from API..."

            $attributes = Get-Attribute


            # https://developers.brevo.com/reference/templatepreview


            #-----------------------------------------------
            # CREATE RENDERDATA
            #-----------------------------------------------

            # TODO replace with real data from test recipient
            $renderParams = [Ordered]@{
                "Firstname" = "John"
                "Lastname" = "Doe"
            }

            $renderBody = [PSCustomObject]@{
                "templateId" = $mailing.mailingId
                "email" = $testRecipient.Email
                "params" = [PSCustomObject]$renderParams
            }


            #-----------------------------------------------
            # UP- AND DOWNLOAD RECEIVER
            #-----------------------------------------------

            # Output the request body for debug purposes
            Write-Log -Message "Debug Mode: $( $Script:debugMode )"
            If ( $Script:debugMode -eq $true ) {
                $tempFile = ".\$( $i )_$( [guid]::NewGuid().tostring() )_request.txt"
                Set-Content -Value ( ConvertTo-Json $uploadBody -Depth 99 ) -Encoding UTF8 -Path $tempFile
            }

            # As a response we get the full profiles of the receiver back
            $params = [Hashtable]@{
                "Object" = "smtp/template"
                "Method" = "POST"
                "Path" = "preview"
                "Body" = $renderBody
            }
            $preview = Invoke-Brevo @params


            
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


            #-----------------------------------------------
            # CLOSE DEFAULT DUCKDB CONNECTION
            #-----------------------------------------------

            #Close-DuckDBConnection

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

            "Type" = "Email" #Email|Sms
            "FromAddress"=$preview.fromEmail
            "FromName"=$preview.fromName
            "Html"=$preview.html
            "ReplyTo"=""
            "Subject"=$preview.subject
            "Text"=$preview.previewText # TODO maybe this is not correct

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $moduleName
            "ProcessId" = $Script:processId


        }

        # log the return object into logfile
        Write-Log -message "RETURN:"
        $return.Keys | ForEach-Object {
            $param = $_
            Write-Log -message "    $( $param ) = '$( $return[$param] )'" -writeToHostToo $false
        }

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

    end {

    }

}

