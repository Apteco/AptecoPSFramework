function Invoke-Push {

    [CmdletBinding(DefaultParameterSetName = 'File')]
    Param(
        
        [Parameter(Mandatory=$true, ParameterSetName = 'File')]
        [String]$Path

    )

    Process {


        $oldPath = $Path
        Move-Item -Path $Path -Destination "$( $Path ).moved"
        $Path = "$( $Path ).moved"

        ################################################
        #
        # SETTINGS
        #
        ################################################

        $processId = Get-ProcessId

        $maxNotificationsPerSecond = $Script:settings.upload.maxNotificationsPerSecond
        $checkEveryNotifications = $Script:settings.upload.checkEveryNotifications
        $lockfile = $Script:settings.upload.lockfile
        $maxLockfileAge = $Script:settings.upload.maxLockfileAge
        $exclusionFolder = $Script:settings.upload.exclusionFolder

        Write-Log "----------------------------------------------------"
        Write-Log "Using process id $( $processId )"
        Write-Log "Using this file '$( $Path )'"

        $urnFieldName = $script:settings.upload.urnFieldName
        $informTokens = $script:settings.upload.informTokens


        ################################################
        #
        # PROGRAM
        #
        ################################################


        #-----------------------------------------------
        # LOAD DUCKDB
        #-----------------------------------------------

        Write-Log "Loading DuckDB..."

        # Load DuckDB and bouncycastle
        Import-Dependency -LoadWholePackageFolder # TODO Should not be necessary for duckdb, but we also need bouncycastle

        # Add DuckDB connection
        # TODO could be replaced with duckdb commands from AptecoPSFramework
        $connectionString = $Script:settings.upload.duckConnectionString
        $duck = [DuckDB.NET.Data.DuckDBConnection]::new($connectionString) # TODO maybe add parameter to only load strings
        $duck.open()

        Write-Log "[OK] DuckDB loaded and connection open to '$( $connectionString )'"


        #-----------------------------------------------
        # LOAD PUSH LIBRARIES
        #-----------------------------------------------

        Write-Log "Loading bouncy castle..."

        # Load bouncy castle for push
        $json = Get-Content $Script:settings.serviceAccountKeyPath -Raw | ConvertFrom-Json
        $Script:variableCache.Add("json", $json)

        # Lade den privaten Schlüssel
        $sr = [System.IO.StringReader]::new($json.private_key)
        $reader = [Org.BouncyCastle.OpenSsl.PemReader]::new($sr)
        $keyPair = [Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters]$reader.ReadObject() #[Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]
        $rsaParams = [Org.BouncyCastle.Security.DotNetUtilities]::ToRSAParameters($keyPair)

        $rsa = [System.Security.Cryptography.RSA]::Create()
        $rsa.ImportParameters($rsaParams)

        $Script:variableCache.Add("accessToken","")
        $Script:variableCache.Add("exp", 0)

        Write-Log "[OK] Bouncy castle and settings loaded"


        #-----------------------------------------------
        # LOAD DATA
        #-----------------------------------------------

        Write-Log "Loading input file with DuckDB..."

        $duckCommand = $duck.createCommand()
        $sb = [System.Text.StringBuilder]::new()
        $sb.Append( "SELECT * FROM read_csv('$( $Path )')" ) | Out-Null
        If ( (Get-ChildItem -Path $exclusionFolder -Filter "*.csv").Count -gt 0 ) {
            $sb.Append( "WHERE token not in ( SELECT token from read_csv('$( $exclusionFolder )/*.csv', union_by_name = true) WHERE error = '404' )" ) | Out-Null
        }
        $duckCommand.CommandText = $sb.toString()
        $reader = $duckCommand.ExecuteReader()

        $returnPSCustomArrayList = [System.Collections.ArrayList]@()
        While ($reader.read()) {

            # Create object and fill it
            $returnPSCustom = [Ordered]@{}
            For ($x = 0; $x -lt $reader.FieldCount; $x++ ) {
                # TODO support other return types than string
                if ($reader.IsDBNull($x) -eq $true ) {
                    $returnPSCustom[$reader.GetName($x)] = $null
                } else {
                    $returnPSCustom[$reader.GetName($x)] = $reader.GetValue($x) #$reader.GetString($x)
                }
            }

            [void]$returnPSCustomArrayList.Add([PSCustomObject]$returnPSCustom)

        }
        $notifications = [System.Collections.ArrayList]@()
        $notifications.addrange( $returnPSCustomArrayList ) | Out-Null

        Write-Log "[OK] Input file loaded (already with exclusions):"


        #-----------------------------------------------
        # LOGGING
        #-----------------------------------------------

        $totalRows = measure-rows -Path $Path -SkipFirstRow

        #Write-Log "Input data:"
        Write-Log "  Total token: $( $totalRows )"
        Write-Log "  Exclusions: $( $totalRows - $notifications.count )"
        Write-Log "  Remaining token: $( $notifications.count )"


        #-----------------------------------------------
        # PREPARE HTTPCLIENT
        #-----------------------------------------------

        Write-Log "Opening HttpClient..."

        # HttpClient
        $Script:variableCache.add("client", [System.Net.Http.HttpClient]::new() )

        Write-Log "[OK] HttpClient ready"


        #-----------------------------------------------
        # BUILDING UPLOAD DATA
        #-----------------------------------------------

        $Script:variableCache.add("fcmUrl", "$( $Script:settings.base )/projects/$( $script:settings.login.projectId )/messages:send")

        Write-Log "Using this url '$( $Script:variableCache.fcmUrl )'"
        Write-Log "Transforming data:"

        $notificationsArr = [System.Collections.ArrayList]@()
        $i = 0
        $notifications | ForEach-Object {

            $notif = $_

            # TODO implement image
            $payload = [Ordered]@{
                "message" = [Ordered]@{
                    "notification" = [Ordered]@{
                        "title" = $notif."PN.Title"
                        "body" = $notif."PN.Text" #"Hallo, dies ist ein Test von Apteco. Bitte Alex Bescheid geben."
                    }
                    "data" = [Ordered]@{
                        "route" = $notif."route"
                        "type" = $notif."type"
                        "url" = $notif."url"
                        #"firstname" = $notification.firstname
                        #"PU Id" = $notif."PU Id"
                    }
                    "token" = $notif.token
                }
            }

            $notifObj = [Ordered]@{
                "token" = $notif.token
                "payload" = ConvertTo-Json -InputObject $payload -Compress -Depth 99
            }

            $notificationsArr.Add( [PSCustomObject]$notifObj ) | Out-Null
            $i += 1

            If ( $notificationsArr.Count % 1000 -eq 0 -or $notifications.Count -eq $i ) { # TODO change to 10k later
                Write-Log "  $( $i ) done"
            }

        }


        #-----------------------------------------------
        # WAIT FOR LOCKFILE
        #-----------------------------------------------

        # Only proceed if no lock file is present
        While ( (Test-Path -Path $lockfile) -eq $True  ) {  
            
            Start-Sleep -Seconds 20
            Write-Log "Waiting for lockfile '$( $lockfile )' to be removed."

            # Remove lockfile if too old
            If ( Test-Path -path $lockfile ) {
                $lockfileAge = New-TimeSpan -Start ( get-item -Path $lockfile ).LastWriteTime -end ([datetime]::now)
                If ( $lockfileAge.TotalHours -gt $maxLockfileAge ) {
                    Write-Log "Lockfile is too old. Removing it now."
                    Remove-Item -Path $lockfile -Force
                }
            }

        }


        #-----------------------------------------------
        # CREATE LOCKFILE
        #-----------------------------------------------

        Write-Log "Lockfile is removed, creating a new one at '$( $lockfile )'"
        Get-ProcessId | Set-Content -Path $lockfile -encoding utf8


        #-----------------------------------------------
        # SEND PUSH
        #-----------------------------------------------

        Write-Log "Start sending notifications with max $( $maxNotificationsPerSecond ) per second and checking every $( $checkEveryNotifications ) notifications..."

        [int]$initialDelaySeconds = 1
        $delay = $initialDelaySeconds
        $i = 0
        $successful = 0
        $batches = 0
        $tasks = [System.Collections.ArrayList]@()
        $tasksToRemove = [System.Collections.ArrayList]@()
        $notificationsRepeat = [System.Collections.ArrayList]@()
        $failedToken = [System.Collections.ArrayList]@()
        $increaseDelay = $false
        $startBeforeUpload = [datetime]::now
        $success = $False
        Try {

            # Main sending loop with rate control
            $interval = 1 / $maxNotificationsPerSecond * 1000  # milliseconds per message
            Do {

                #$notifications | Where-Object { $_.token -notin $exlusionlist.token } | ForEach-Object {
                # $notificationsArr | ForEach-Object -Parallel -ThrottleLimit 2 { # TODO for future parallel threads
                $notificationsArr | ForEach-Object {

                    # Current Threadid: [System.Threading.Thread]::CurrentThread.ManagedThreadId # TODO for future parallel threads
                    # With $Using:varAbc you create a copy for variables used in the thread
                    # To share variables over synced objects, create this variable outside the loop
                    # $sync = [hashtable]::Synchronized(@{ count = 0 })
                    # then access it like $using:sync.count++ in the loop
                    # Other synced object types are ConcurrentQueue, ConcurrentBag

                    $notif = $_

                    $taskDuration = Measure-Command {
                        $responseTask = Send-FcmNotification -NotificationJson $notif.payload
                    }
                    $responseObj = [Ordered]@{
                        "id" = $i
                        "task" = $responseTask
                        "notification" = $notif
                    }
                    $tasks.Add( $responseObj ) | Out-Null
                    $i += 1
                    
                    # Count and sleep
                    $remainingTime = $interval - $taskDuration.TotalMilliseconds
                    Start-Sleep -Milliseconds ( [Math]::Max(0, $remainingTime) ) # The /2 is just from testing. In there we uploaded 6000 records in 120 seconds, which is 50 records per second, but 100 was the setting

                    If ( $i % 1000 -eq 0 -or $i -eq $notificationsArr.Count ) {
                        Write-Log "  Already done $( $i )"
                    }

                    # Check the results every n calls or at the end
                    If ( $i % $checkEveryNotifications -eq 0 -or $i -eq $notificationsArr.Count ) {

                        #Write-Log "  Checking at $( $i )"

                        # Go through tasks
                        for ( $j = 0; $j -lt $tasks.Count; $j++ ) {

                            $t = $tasks[$j]
                            
                            If ( $t.task.IsCompleted -eq $True ) {

                                Switch ( $t.task.result.StatusCode.value__ ) {

                                    # 200 to ok
                                    200 {
                                        $successful += 1
                                        break
                                    }

                                    # 429 to repeat
                                    429 {
                                        $notificationsRepeat.Add( $t.notification ) | Out-Null
                                        $increaseDelay = $True
                                        break
                                    }
                                    
                                    # 404 will be written to failed
                                    404 {
                                        $failObj = [Ordered]@{
                                            "error" = 404
                                            "token" = $t.notification.token # TODO rework the token thing here
                                            "message" = "Not found"
                                        }
                                        $failedToken.add( [PSCustomObject]$failObj ) | Out-Null 
                                        break
                                    }

                                    # log any other error
                                    default {
                                        
                                        $failObj = [Ordered]@{
                                            "error" = $t.result.StatusCode.value__
                                            "token" = $t.notification.token # TODO rework the token thing here
                                            "message" = ""
                                        }
                                        $failedToken.add( [PSCustomObject]$failObj ) | Out-Null 
                                        #$tbody = $t.Content.ReadAsStringAsync().Result
                                    }

                                }

                                $tasksToRemove.Add($j) | Out-Null
                            
                            }

                            # All done, remove task in reverse order
                            for ( $j = $tasksToRemove.Count -1; $j -ge 0; $j-- ) {
                                $tasks.RemoveAt($tasksToRemove[$j])
                            }
                            $tasksToRemove.Clear()

                        }

                        # Exponential backoff (double delay, capped at 32 seconds)
                        If ( $increaseDelay -eq $True ) {
                            $delayBefore = $delay
                            $delay = [Math]::Min($delay * 2, 32)
                            Write-Log "Increasing delay from $( $delayBefore ) to $( $delay )"
                            Start-Sleep -Seconds $delay
                            $increaseDelay = $False
                        }

                        #Write-Log "  Checking done $( $i )"

                    }

                }

                $batches += 1

                # prepare the next batch
                $notificationsArr.Clear()
                $notificationsRepeat.CopyTo($notificationsArr)

            } While ( $notificationsArr.count -ne 0 )

            $success = $True

        } catch {

            $msg = "Error during uploading data in line $( $i ). Abort!"
            Write-Log -Message $msg -Severity ERROR #-WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_

        } finally {

            Write-Log "Removing lockfile now"
            Remove-Item -Path $lockfile -Force

            $totalTimeUpload = New-TimeSpan -Start $startBeforeUpload -End ( [DateTime]::now )

            Write-Log "Results:"
            Write-Log "  $( [math]::ceiling($totalTimeUpload.TotalSeconds) ) seconds to upload $( $i ) notifications"
            Write-Log "  $( [math]::ceiling( $i / $totalTimeUpload.TotalSeconds )) average notifications per second"
            Write-Log "  $( $batches ) batches to upload"
            Write-Log "  $( $successful ) successful token"
            Write-Log "  $( $failedToken.Count ) failed token"

            Write-Log "Writing exclusion file, when more than 0 failed token"
            If ($failedToken.Count -gt 0 ) {
                $exclusionFile = "$( $exclusionFolder )\$( $processId ).csv"
                Write-Log "  Writing exclusion file to '$( $exclusionFile )'"
                $failedToken | Export-Csv -Path $exclusionFile -Encoding utf8 -Delimiter "`t" -NoTypeInformation
            }

        }


        #-----------------------------------------------
        # FORCE FOLLOW PROCESSES TO DO NOTHING
        #-----------------------------------------------

        If ( $success -eq $True ) {

            $sb = [System.Text.StringBuilder]::new()
            $sb.Append( "COPY (" ) | Out-Null
            If ( $informTokens.Count -gt 0 ) {
                $sb.Append( "SELECT * Exclude(""PN.Text""), 'Successfully uploaded $( $successful ) tokens' as ""PN.Text"" FROM read_csv('$( $Path )') WHERE ""$( $urnFieldName )"" in ('$( $informTokens -join "', '" )')" ) | Out-Null
            } else {
                # Just use a random record
                $sb.Append( "SELECT * FROM read_csv('$( $Path )') ORDER BY RANDOM() LIMIT 1" ) | Out-Null
            }
            $sb.Append( ") TO '$( $Path ).new' (FORMAT CSV, DELIMITER '\t', QUOTE '')" ) | Out-Null

            $duckCommand = $duck.createCommand()
            $duckCommand.CommandText = $sb.ToString()
            $result = $duckCommand.ExecuteNonQuery()

            Write-Log "Result of original file creation: $( $result )"

            # delete the file if there are less than 1 rows
            If ( $result -gt 0 ) {
                
            } else {
                Remove-Item -Path "$( $Path ).new" -Force
            }

            # Wait for 5 seconds until file is released
            Start-Sleep -Seconds 5

            # Replace original file, if a new one was created
            If ( Test-Path -Path "$( $Path ).new" ) {
                If ( (get-item "$( $Path ).new" ).Length -gt 0 ) {
                    #Move-Item -Path $Path -Destination "$( $Path ).moved" -Force
                    Move-Item -Path  "$( $Path ).new" -Destination $oldPath -Force
                }
            }
            
            # Check if the file really exist now
            If ( Test-Path -Path $oldPath ) {
                Write-Log "Original path exists at '$( $oldPath )'"

            # If the original file does not exist, create the file with a random record
            } else {
                Write-Log "Original path not exists at '$( $oldPath )'"
                $sb.Clear()
                $sb.Append( "COPY (" ) | Out-Null
                $sb.Append( "SELECT * Exclude(token), left(token,30) as token FROM read_csv('$( $Path )') ORDER BY RANDOM() LIMIT 1" ) | Out-Null
                $sb.Append( ") TO '$( $Path ).new' (FORMAT CSV, DELIMITER '\t', QUOTE '')" ) | Out-Null
                $duckCommand = $duck.createCommand()
                $duckCommand.CommandText = $sb.ToString()
                $result = $duckCommand.ExecuteNonQuery()
                Move-Item -Path  "$( $Path ).new" -Destination $oldPath -Force
            }

            $duck.Close()
            
        }

    }

}