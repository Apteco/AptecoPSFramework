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

    process {

        If ( $Script:variableCache.accessToken -eq "" -or ( $Script:variableCache.exp - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -lt 60 ) ) {
            
            # Erstelle das JWT
            $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            $Script:variableCache.exp = $now + 3600
            $header = @{
                alg = "RS256"
                typ = "JWT"
            }
            $claimSet = @{
                iss = $Script:variableCache.json.client_email
                scope = "https://www.googleapis.com/auth/cloud-platform"
                aud = "https://oauth2.googleapis.com/token"
                iat = $now
                exp = $Script:variableCache.exp
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
            $Script:variableCache.accessToken = $response.access_token

            $Script:variableCache.client.DefaultRequestHeaders.Authorization = "Bearer $( $Script:variableCache.accessToken )"
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
            $responseTask = $Script:variableCache.client.PostAsync($Script:variableCache.fcmUrl, $content)

        } catch {
            # TODO do something else here
        }

        #return
        $responseTask

    }

}
