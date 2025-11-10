
################################################
#
# INPUT
#
################################################

Param(
     [String]$Path
    #,[String]$GenerateSerials
)


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false


#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug -eq $true ) {

    $Path = 'C:\FastStats\Scripts\fcm\PushNotifications_b4782c45-6212-4cda-a57b-5645fc1cc159.txt'

}


################################################
#
# SCRIPT ROOT
#
################################################

# Some local settings
# $dir = $params.scriptRoot
Set-Location "C:\FastStats\Scripts\fcm"
#Import-Module ImportDependency


################################################
#
# NOTES
#
################################################

<#

To be defined

#>

################################################
#
# SETTINGS
#
################################################

$serviceAccountKey = "C:\FastStats\Scripts\fcm\fcmproject-firebase-adminsdk-9bsua-7df6c10a3a.json"
$projectId = "fcmproject"
$apiVersion = "v1"
$base = "https://fcm.googleapis.com"

Set-Logfile "C:\FastStats\Scripts\fcm\fcm.log"
$processId = Get-ProcessId

$maxNotificationsPerSecond = 100
$checkEveryNotifications = 200
$lockfile = "C:\temp\push.lock"
$maxLockfileAge = 3 #hours
$exclusionFolder = "C:\FastStats\Scripts\fcm\exclusions"

Write-Log "----------------------------------------------------"
Write-Log "Using process id $( $processId )"
Write-Log "Using this file '$( $Path )'"

$urnFieldName = "PU Id"
$informTokens = @(

    # Florian DE
    "620967"
)


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# LOAD KERNEL32
#-----------------------------------------------

Write-Log "Loading Kernel32..."

Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class Kernel32 {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadLibrary(string lpFileName);
    public static string GetError() { return Marshal.GetLastWin32Error().ToString(); }
    public static bool GetEnv() { return Environment.Is64BitProcess; }
}
"@

Write-Log "[OK] Loaded Kernel32"


#-----------------------------------------------
# LOAD DUCKDB
#-----------------------------------------------

Write-Log "Loading DuckDB..."

# Load duck DB
add-type -Path "C:\FastStats\Scripts\fcm\lib\DuckDB.NET.Bindings.Full.1.4.1\lib\net8.0\DuckDB.NET.Bindings.dll"
Add-Type -Path "C:\FastStats\Scripts\fcm\lib\DuckDB.NET.Data.Full.1.4.1\lib\net8.0\DuckDB.NET.Data.dll"

# Add native dll
[void][Kernel32]::LoadLibrary("C:\FastStats\Scripts\fcm\lib\DuckDB.NET.Bindings.Full.1.4.1\runtimes\win-x64\native\duckdb.dll")

# Add DuckDB connection
$connectionString = "Data Source=:memory:"
$duck = [DuckDB.NET.Data.DuckDBConnection]::new($connectionString) # TODO maybe add parameter to only load strings
$duck.open()

Write-Log "[OK] DuckDB loaded and connection open to '$( $connectionString )'"


#-----------------------------------------------
# LOAD PUSH LIBRARIES
#-----------------------------------------------

Write-Log "Loading bouncy castle..."

# Load bouncy castle for push
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\BouncyCastle.Cryptography.2.5.0\lib\net461\BouncyCastle.Cryptography.dll"
$json = Get-Content $serviceAccountKey -Raw | ConvertFrom-Json

# Lade den privaten Schlüssel
$sr = [System.IO.StringReader]::new($json.private_key)
$reader = [Org.BouncyCastle.OpenSsl.PemReader]::new($sr)
$keyPair = [Org.BouncyCastle.Crypto.Parameters.RsaPrivateCrtKeyParameters]$reader.ReadObject() #[Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]
$rsaParams = [Org.BouncyCastle.Security.DotNetUtilities]::ToRSAParameters($keyPair)

$rsa = [System.Security.Cryptography.RSA]::Create()
$rsa.ImportParameters($rsaParams)

$Script:accessToken = ""
$Script:exp = 0

Write-Log "[OK] Bouncy castle loaded"


#-----------------------------------------------
# LOAD DATA
#-----------------------------------------------

Write-Log "Loading input file with DuckDB..."

$duckCommand = $duck.createCommand()
# TODO load exclusion list into the statement?
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
#$notifications.addrange( $returnPSCustomArrayList[0..6000] ) | Out-Null
$notifications.addrange( $returnPSCustomArrayList ) | Out-Null

#$returnPSCustomArrayList.CopyTo($notifications)

# TODO Maybe create single files that will be used for sendout

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
# LOAD EXCLUSIONS
#-----------------------------------------------

<#
# Delete exclusion files older than x days
Get-ChildItem -Path $exclusionFolder -Filter "*.csv" | ForEach-Object {
    $path = $_.FullName
    $ts = New-TimeSpan -Start $_.LastWriteTime -end ( [DateTime]::Now )
    If ( $ts.TotalDays -gt 65 ) {
        Remove-Item -Path $path -force
    }
}

$exlusionlist = [System.Collections.ArrayList]@()
If (( Get-Childitem -Path $exclusionFolder -Filter "*.csv" ).Count -gt 0) {
    $duckCommand = $duck.createCommand()
    $duckCommand.CommandText = "Select * from read_csv('$( $exclusionFolder )/*.csv', union_by_name = true);"
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

    #$returnPSCustomArrayList.CopyTo($exlusionlist)
    $exlusionlist.AddRange( $returnPSCustomArrayList ) |Out-Null

}
#>

#-----------------------------------------------
# PREPARE HTTPCLIENT
#-----------------------------------------------

Write-Log "Opening HttpClient..."

# HttpClient
$Script:client = [System.Net.Http.HttpClient]::new()

Write-Log "[OK] HttpClient ready"


#-----------------------------------------------
# BUILDING UPLOAD DATA
#-----------------------------------------------


$Script:fcmUrl = "$( $base )/$( $apiVersion )/projects/$( $projectId )/messages:send"

Write-Log "Using this url '$( $Script:fcmUrl )'"
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
                "body" = $notif."PN.Text"
            }
            "data" = [Ordered]@{
                "route" = $notif."route"
                "type" = $notif."type"
                "url" = $notif."url"
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
# DEFINE SEND FUNCTION
#-----------------------------------------------

# Function to send a single notification with dynamic backoff
#$postedTasks = [System.Collections.ArrayList]@()
function Send-FcmNotification {
    
    [CmdletBinding(DefaultParameterSetName = 'PayloadToParse')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'ParsedPayload')]
         [String]$NotificationJson
        
        ,[Parameter(Mandatory=$true, ParameterSetName = 'PayloadToParse')]
         [PSCustomObject]$NotificationObject

    )

    begin {



    }

    process {

        # TODO create a separate function for that?
        # refresh the token when it expires or there is no accesstoken
        If ( $Script:accessToken -eq "" -or ( $Script:exp - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -lt 60 ) ) {
            
            # Erstelle das JWT
            $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            $Script:exp = $now + 3600
            $header = @{
                alg = "RS256"
                typ = "JWT"
            }
            $claimSet = @{
                iss = $Script:json.client_email
                scope = "https://www.googleapis.com/auth/cloud-platform"
                aud = "https://oauth2.googleapis.com/token"
                iat = $now
                exp = $Script:exp
            }
            $headerJson = $header | ConvertTo-Json -Compress
            $claimSetJson = $claimSet | ConvertTo-Json -Compress
            $headerBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($headerJson))
            $claimSetBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($claimSetJson))
            $unsignedToken = "$( $headerBase64 ).$( $claimSetBase64 )"

            # Signiere das JWT
            $signature = $rsa.SignData([System.Text.Encoding]::UTF8.GetBytes($unsignedToken), [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
            $signedToken = "$unsignedToken." + [Convert]::ToBase64String($signature)

            # Get the token
            $response = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body @{
                grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
                assertion = $signedToken
            }
            $Script:accessToken = $response.access_token

            $Script:client.DefaultRequestHeaders.Authorization = "Bearer $( $Script:accessToken )"
            #$Script:client.DefaultRequestHeaders.TryAddWithoutValidation("Content-Type", "application/json; charset=utf-8")

            Write-Log "Refreshed access token" -Severity INFO

        }

        # replacing json
        switch ($PSCmdlet.ParameterSetName) {

            'ParsedPayload' {

                # Create params
                $payloadJson = $NotificationJson

                break
            }

            'PayloadToParse' {

                $payload = [Ordered]@{
                    "message" = [Ordered]@{
                        "notification" = [Ordered]@{
                            "title" = $NotificationObject."PN.Title"
                            "body" = $NotificationObject."PN.Text"
                        }
                        "data" = [Ordered]@{
                            "route" = $NotificationObject."route"
                            "type" = $NotificationObject."type"
                            "url" = $NotificationObject."url"
                            #"firstname" = $notification.firstname
                            #"PU Id" = $notif."PU Id"
                        }
                        "token" = $NotificationObject.token
                    }
                }

                $payloadJson = ConvertTo-Json -InputObject $payload -Compress -Depth 99
                
                break
            }
        }

        $responseTask = $null
        try {

            #Write-Verbose $fcmUrl -Verbose
            $content = [System.Net.Http.StringContent]::new($payloadJson, [System.Text.Encoding]::UTF8, "application/json")
            $responseTask = $Script:client.PostAsync($Script:fcmUrl, $content)

        } catch {
            # TODO do something else here
        }

        #return
        $responseTask

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
        $notificationsArr | ForEach-Object {

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

    $duck.Close()

    # Wait for 5 seconds until file is released
    Start-Sleep -Seconds 5

    # Replace original file, if a new one was created
    If ( Test-Path -Path "$( $Path ).new" ) {
        If ( (get-item "$( $Path ).new" ).Length -gt 0 ) {
            Move-Item -Path $Path -Destination "$( $Path ).moved" -Force
            Move-Item -Path  "$( $Path ).new" -Destination $Path -Force
        }
    }
    
}

################################################
#
# EXIT
#
################################################

If ( $success -eq $True ) {
    Exit 0
} Else {
    Exit 4
}