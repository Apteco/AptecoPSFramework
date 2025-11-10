
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

$maxNotificationsPerSecond = 50
$lockfile = "C:\temp\push.lock"
$maxLockfileAge = 3 #hours


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# LOAD KERNEL32
#-----------------------------------------------

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

#-----------------------------------------------
# LOAD DUCKDB
#-----------------------------------------------

# Load duck DB
add-type -Path "C:\FastStats\Scripts\fcm\lib\DuckDB.NET.Bindings.Full.1.4.1\lib\net8.0\DuckDB.NET.Bindings.dll"
Add-Type -Path "C:\FastStats\Scripts\fcm\lib\DuckDB.NET.Data.Full.1.4.1\lib\net8.0\DuckDB.NET.Data.dll"

# Add native dll
[void][Kernel32]::LoadLibrary("C:\FastStats\Scripts\fcm\lib\DuckDB.NET.Bindings.Full.1.4.1\runtimes\win-x64\native\duckdb.dll")

# Add DuckDB connection
$duck = [DuckDB.NET.Data.DuckDBConnection]::new("Data Source=:memory:") # TODO maybe add parameter to only load strings
$duck.open()


#-----------------------------------------------
# LOAD PUSH LIBRARIES
#-----------------------------------------------

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


#-----------------------------------------------
# LOAD DATA
#-----------------------------------------------

$duckCommand = $duck.createCommand()
# TODO load exclusion list into the statement?
$duckCommand.CommandText = "Select * from read_csv('$( $Path )') ;"
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
$notifications.addrange( $returnPSCustomArrayList[0..6000] ) | Out-Null
#$notifications.addrange( $returnPSCustomArrayList ) | Out-Null

#$returnPSCustomArrayList.CopyTo($notifications)

# TODO Maybe create single files that will be used for sendout

#-----------------------------------------------
# LOAD EXCLUSIONS
#-----------------------------------------------

$exclusionFolder = "C:\FastStats\Scripts\fcm\exclusions"

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


#-----------------------------------------------
# PREPARE HTTPCLIENT
#-----------------------------------------------

# HttpClient
$Script:client = [System.Net.Http.HttpClient]::new()


#-----------------------------------------------
# DEFINE SEND FUNCTION
#-----------------------------------------------

# Function to send a single notification with dynamic backoff
#$postedTasks = [System.Collections.ArrayList]@()
function Send-FcmNotification {
    
    param(
        
        [PSCustomObject]$notification

    )

    begin {

    }

    process {

        # refresh the token when it expires or there is no accesstoken
        If ( $Script:accessToken -eq "" -or ( $exp - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -lt 60 ) ) {
            
            # Erstelle das JWT
            $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            $exp = $now + 3600
            $header = @{
                alg = "RS256"
                typ = "JWT"
            }
            $claimSet = @{
                iss = $json.client_email
                scope = "https://www.googleapis.com/auth/cloud-platform"
                aud = "https://oauth2.googleapis.com/token"
                iat = $now
                exp = $exp
            }
            $headerJson = $header | ConvertTo-Json -Compress
            $claimSetJson = $claimSet | ConvertTo-Json -Compress
            $headerBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($headerJson))
            $claimSetBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($claimSetJson))
            $unsignedToken = "$headerBase64.$claimSetBase64"

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

        $fcmUrl = "$( $base )/$( $apiVersion )/projects/$( $projectId )/messages:send"
        # TODO implement image and more flexibility
        $payload = [Ordered]@{
            "message" = [Ordered]@{
                "notification" = [Ordered]@{
                    "title" = $notification."PN.Title"
                    "body" = $notification."PN.Text"
                }
                "data" = [Ordered]@{
                    "route" = $notification.route
                    "type" = $notification.type
                    "url" = $notification.url
                    "firstname" = $notification.firstname
                    "PU Id" = $notification."PU Id"
                }
                "token" = $notification.token
            }
        }
        $payloadJson = ConvertTo-Json -InputObject $payload -Compress -Depth 99
        #Write-Verbose $payloadJson -verbose

        #return
        $responseTask = $null
        try {

            #Write-Verbose $fcmUrl -Verbose
            $content = [System.Net.Http.StringContent]::new($payloadJson, [System.Text.Encoding]::UTF8, "application/json")
            $responseTask = $Script:client.PostAsync($fcmUrl, $content)

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
    
    Start-Sleep -Seconds 5
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

Get-ProcessId | Set-Content -Path $lockfile -encoding utf8


#-----------------------------------------------
# SEND PUSH
#-----------------------------------------------

[int]$initialDelaySeconds = 1
$delay = $initialDelaySeconds
$i = 0
$successful = 0
$batches = 0
$tasks = [System.Collections.ArrayList]@()
$notificationsRepeat = [System.Collections.ArrayList]@()
$failedToken = [System.Collections.ArrayList]@()
$increaseDelay = $false
Try {

    # Main sending loop with rate control
    $interval = 1 / $maxNotificationsPerSecond  # seconds per message
    Do {

        $notifications | Where-Object { $_.token -notin $exlusionlist.token } | ForEach-Object {

            $notif = $_

            $responseTask = Send-FcmNotification -notification $notif
            $responseObj = [Ordered]@{
                "id" = $i
                "task" = $responseTask
                "notification" = $notif
            }
            $tasks.Add( $responseObj ) | Out-Null
            
            # Count and sleep
            $i += 1
            Start-Sleep -Seconds $interval

            # Check the results every n calls or at the end
            If ( $i % 100 -eq 0 -or $i -eq $notifications.Count ) {

                Write-Log "Already done $( $i )"

                # Go through tasks in reverse order
                for ( $j = $tasks.Count -1; $j -ge 0; $j-- ) {

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
                                $notificationsRepeat.Add( $t.notification )
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
                                $failedToken.add( [PSCustomObject]$failObj  ) | Out-Null 
                                break
                            }

                            # log any other error
                            default {
                                
                                $failObj = [Ordered]@{
                                    "error" = $t.result.StatusCode.value__
                                    "token" = $t.notification.token # TODO rework the token thing here
                                }
                                $failedToken.add( [PSCustomObject]$failObj  ) | Out-Null 
                                #$tbody = $t.Content.ReadAsStringAsync().Result
                            }

                        }

                        # All done, remove task
                        $tasks.RemoveAt($j)
                    
                    }

                }

                # Exponential backoff (double delay, capped at 32 seconds)
                If ( $increaseDelay -eq $True ) {
                    $delay = [Math]::Min($delay * 2, 32)
                    Start-Sleep -Seconds $delay
                    $increaseDelay = $False
                }

            }

        }

        $batches += 1

        # prepare the next batch
        $notifications.Clear()
        $notificationsRepeat.CopyTo($notifications)

    } While ( $notifications.count -ne 0 )

    Write-Log "Needed $( $batches ) batches"

} catch {
    # TODO catch it
} finally {

    Remove-Item -Path $lockfile -Force

    If ($failedToken.Count -gt 0 ) {
        $failedToken | Export-Csv -Path "$( $exclusionFolder )\$( $processId ).csv" -Encoding utf8 -Delimiter "`t" -NoTypeInformation
    }

}

exit 0

#-----------------------------------------------
# FORCE FOLLOW PROCESSES TO DO NOTHING
#-----------------------------------------------

# Rewrite original file with just one line
Move-Item -Path $Path -Destination "$( $Path ).moved"
# TODO save duckdb with headers and one line into this file


################################################
#
# EXIT
#
################################################

exit 0


