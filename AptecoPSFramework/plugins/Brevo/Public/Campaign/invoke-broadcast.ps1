

function Invoke-Broadcast {
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

        $moduleName = "BROADCAST"


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
        # GET VALUES FROM UPLOAD
        #-----------------------------------------------

        $listId = $params.GroupId
        $totalRecipients = $params.ReceiversTotal


    }

    process {

        try {

            #-----------------------------------------------
            # FIND OUT MAILING TEMPLATE
            #-----------------------------------------------

            # Get all active templates to filter then
            $template = $null
            $templates = Get-Template -TemplateStatus "active" -All #| select id, name, subject, isActive, testSent, replyTo, toField, tag, createdAt, modifiedAt
            $template = $templates | where-object { $_.id -eq $mailing.mailingId }
            If ( $null -eq $template ) {
                throw "Could not find template with id '$( $mailing.mailingId )' in Brevo"
            } else {
                Write-Log "Found template '$( $template.name )' with id '$( $template.id )' in Brevo"
            }

            #-----------------------------------------------
            # GET ALL SEGMENTS
            #-----------------------------------------------

            # Get all segments to filter then
            $segments = Get-Segment


            #-----------------------------------------------
            # CHECK IF UPDATEFORMID IS NEEDED
            #-----------------------------------------------

            # Check if updateFormId is mandatory
            $requiresUpdateFormId = $false
            if ( $template.htmlContent  -match '\{\{\s*update_profile\s*\}\}' ) {
                $requiresUpdateFormId = $True
                Write-Log "Template contains update_profile tag, updateFormId is mandatory"
            } else {
                Write-Log "Template does not contain update_profile tag, updateFormId is not mandatory"
            }
            If ( $requiresUpdateFormId -eq $true -and (( $null -eq $Script:settings.broadcast.defaultUpdateFormId -or $Script:settings.broadcast.defaultUpdateFormId -eq "" ) -or ( $InputHashtable.updateFormId -eq "" )) ) {
                throw "Template requires updateFormId, but none is set in the settings"
            }


            #-----------------------------------------------
            # CREATE THE CAMPAIGN FROM TEMPLATE
            #-----------------------------------------------

            # https://developers.brevo.com/reference/updateemailcampaign
            # TODO make this name changeable from settings yaml file
            $campaignName = "$( $ProcessStart.toString("yyyy-MM-dd") )_$( $mailing.mailingName )_$( $ProcessStart.toString("HH:mm") )"
            $campaignBody = [Ordered]@{
                "tag" = $Script:settings.broadcast.tag
                "sender" = [PSCustomObject]@{
                    "name" = $template.sender.name
                    "email" = $template.sender.email
                }
                "name" = $campaignName
                "templateId" = $template.id #$mailing.mailingId
                "subject" = $template.subject
                #"previewText" = "" # TODO is this in the template or take from data?
                #"replyTo" = $template.replyTo # TODO make this configurable later?
                "toField" = $template.toField
                #"attachmentUrl" = "" # TODO can be implemented later
                "mirrorActive" = $Script:settings.broadcast.mirrorActive
                #"utmCampaign" = "" # TODO check if should be implemented
                #"unsubscriptionPageId" = "" # TODO check if should be implemented
                "recipients" = [PSCustomObject]@{
                    "listIds" = [Array]@( [long]$listId )
                    #"segmentIds" = @() # TODO add segment filtering later
                }
                #"inlineImageActivation" = $false
                #"sendAtBestTime" = $false
                #"abTesting" = $false
                #"ipWarmupEnable" = $false
            }

            # If the to field is not set in the template, use the default one
            If ( $null -ne $Script:settings.broadcast.defaultToField -and $Script:settings.broadcast.defaultToField -ne "" -and $template.toField -eq "" ) {
                $campaignBody.toField = $Script:settings.broadcast.defaultToField
            }

            If ( $Script:settings.broadcast.exclusionListIds.Count -gt 0 ) {
                $campaignBody.recipients | Add-Member -MemberType NoteProperty -Name "exclusionListIds" -Value $Script:settings.broadcast.exclusionListIds
            }

            If ( $Script:settings.broadcast.exclusionSegmentIds.Count -gt 0 ) {
                $campaignBody.recipients | Add-Member -MemberType NoteProperty -Name "exclusionSegmentIds" -Value $Script:settings.broadcast.exclusionSegmentIds
            }

            If ( $Script:settings.broadcast.emailExpirationDate -gt -1 ) {
                $campaignBody.Add("emailExpirationDate", $Script:settings.broadcast.emailExpirationDate)
            }

            <#
            Mandatory if templateId is used containing the {{ update_profile }} tag. Enter an update profile form id.
            The form id is a 24 digit alphanumeric id that can be found in the URL when editing the form.
            If not entered, then the default update profile form will be used.
            #>
            If ( $requiresUpdateFormId -eq $true ) {
                If ( $InputHashtable.updateFormId -ne "" ) {
                    $campaignBody.Add("updateFormId", $InputHashtable.updateFormId)
                } else {
                    $campaignBody.Add("updateFormId", $Script:settings.broadcast.defaultUpdateFormId)
                }
            }

            [PSCustomObject]$campaignBody | ConvertTo-Json -Depth 99 | Out-File -FilePath "C:\temp\campaignBody.json" -Encoding UTF8

            $params = [Hashtable]@{
                "Object" = "emailCampaigns"
                "Method" = "POST"
                #"Path" = "preview"
                "Body" = [PSCustomObject]$campaignBody
            }

            # add verbose flag, if set
            If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
                $params.Add("Verbose", $true)
            }
            $campaign = Invoke-Brevo @params


            #-----------------------------------------------
            # IF THAT WAS SUCCESSFUL, LAUNCH THE CAMPAIGN
            #-----------------------------------------------

            If ( [int]$campaign.id -gt 0 ) {
                Write-Log "Created campaign '$( $campaignName )' with id '$( $campaign.id )' from template id '$( $mailing.mailingId )'"
            } else {
                throw "Could not create campaign from template id '$( $mailing.mailingId )'"
            }

            # PUT  https://api.brevo.com/v3/emailCampaigns/{campaignId}/status needed?
            If ( $Script:settings.broadcast.autoLaunch -eq $true -or $InputHashtable.autoLaunch -eq "true" ) {

                $scheduledAt = [DateTime]::Now.AddSeconds($Script:settings.broadcast.defaultReleaseOffset).ToString("yyyy-MM-ddTHH:mm:ssZ") # send 5 minutes in the future to allow for processing time # TODO make configurable
                # Additionally add sendAtBestTime
                If ( $InputHashtable.sendAtBestTime.ToLower() -eq "true" ) {
                    $sendAtBestTime = $true
                } else {
                    $sendAtBestTime = $false
                }

                # Now update the campaign with the sending time if everything is fine
                $updatedTimeBody = [Ordered]@{
                    "scheduledAt" = $scheduledAt
                    "sendAtBestTime" = $sendAtBestTime
                }

                $updatedTimeParams = [Hashtable]@{
                    "Object" = "emailCampaigns"
                    "Method" = "PUT"
                    "Path" = $campaign.id
                    "Body" = [PSCustomObject]$updatedTimeBody
                }

                # add verbose flag, if set
                If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
                    $params.Add("Verbose", $true)
                }
                $updatedCampaign = Invoke-Brevo @updatedTimeParams

                <#
                TODO Implement these parameters
                    "waitUntilFinished" = $false
                    "maxWaitForFinishedAfterOffset" = 120           # Wait for another 120 seconds (or more or less) until it is confirmed of send off

                #>

                # Wait until finished
                If ( $Script:settings.broadcast.waitUntilFinished -eq $true ) {

                    $maxWaitTime = [int]$Script:settings.broadcast.defaultReleaseOffset + [int]$Script:settings.broadcast.maxWaitForFinishedAfterOffset
                    $secondsToWait = 5
                    $i = 0
                    Do {

                        # Wait and count
                        Start-Sleep -Seconds $secondsToWait
                        $i += $secondsToWait

                        # Ask for the current status
                        $statusParams = [Hashtable]@{
                            "Object" = "emailCampaigns"
                            "Method" = "GET"
                            "Path" = $campaign.id
                        }
                        $mailingStatus = Invoke-Brevo @statusParams

                    } Until ( $i -gt $maxWaitTime -or $mailingStatus.status -eq "sent" )

                    # Log the exit of the loop
                    # https://developers.brevo.com/reference/getemailcampaign
                    If ( $mailingStatus.status -eq "sent" ) {
                        # All good
                        Write-Log "Mailing finished successfully after $( $i ) seconds (Offset: $( [int]$Script:settings.broadcast.defaultReleaseOffset ))" -Severity INFO
                    } else {
                        # Something went wrong
                        Write-Log "Mailing exceeded the maximum wait time of $( $maxWaitTime ) seconds with status '$( $mailingStatus.status )'" -Severity WARNING
                    }

                } else {
                    Write-Log "Wait for finish is disabled. Not waiting for mailing to be finished"
                }

            } else {
                Write-Log "Auto launch is disabled, campaign created but not launched"
            }
            <#
            Sending UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). Prefer to pass your timezone in date-time format for accurate result.
            If sendAtBestTime is set to true, your campaign will be sent according to the date passed (ignoring the time part). For example:
            2017-06-01T12:30:00+02:00
            #>

            # TODO Add a segment to exclude bounces etc.

            #-----------------------------------------------
            # LIST ERRORS
            #-----------------------------------------------
<#
            Write-Log "Listing failed reasons..." #-Severity WARNING

            $import.Info.InvalidEmail | group-object Reason | Sort-Object Count -Descending | ForEach-Object {
                $failure = $_
                Write-Log "  $( $failure.Count ) '$( $failure.Name )'" -Severity WARNING
            }
#>
            

            
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
        $recipients = $totalRecipients # TODO check out how to get the number of successful recipients

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

