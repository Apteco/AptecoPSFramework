function Save-NewToken {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][String] $TokenSettingsFile
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

        $createNewToken = $true
        $currentUnixtime = Get-Unixtime


    }

    process {

        #-----------------------------------------------
        # READ EXISTING TOKEN SETTINGS FILE
        #-----------------------------------------------

        If ( (Test-Path -Path $Script:settings.token.tokenSettingsFile ) -eq $true ) {

            $tokenSettings = Get-Content -Path $Script:settings.token.tokenSettingsFile -Raw -Encoding utf8 | ConvertFrom-Json

            If ( $currentUnixtime -lt $tokenSettings.unixtime ) {
                $createNewToken = $false
                If ( $Script:settings.token.encryptTokenFile -eq $true ) {
                    $token = Convert-SecureToPlaintext -String $tokenSettings.accesstoken
                } else {
                    $token = $tokenSettings.accesstoken
                }
    
            }

        }


        #-----------------------------------------------
        # LOAD A TOKEN
        #-----------------------------------------------

        If ( $createNewToken -eq $true ) {

            # Check the url
            If ( $Script:settings.base.endswith("/") -eq $true ) {
                $base = $Script:settings.base
            } else {
                $base = "$( $Script:settings.base )/"
            }

            # Prepare the body
            $body = [PScustomobject]@{
                "grant_type" = "client_credentials"
                "client_id" = $Script:settings.login.clientId
                "client_secret"= ( Convert-SecureToPlaintext $Script:settings.login.clientSecret )
            }
            $bodyJson = ConvertTo-Json -InputObject $body -Depth 99
            
            # Obtain new token
            $newToken = Invoke-RestMethod -uri "$( $base )oauth2/token" -Method Post -Body $bodyJson -ContentType $Script:settings.contentType #-Headers @{"Accept-Encoding"="gzip"}
            
            # empty body variable
            $body = [PScustomobject]@{}

            $validUntilUnixtime = ( Get-Unixtime ) + [int]( $newToken.expires_in )
            $validUntilDatetime = ConvertFrom-UnixTime -Unixtime $validUntilUnixtime -ConvertToLocalTimezone
            Write-Log -message "Got new token valid until $( $validUntilDatetime.ToString("yyyy-MM-dd HH:mm:ss") )"

            $token = $newToken.access_token

        }


        #-----------------------------------------------
        # SAVE TOKEN TO CACHE
        #-----------------------------------------------

        # Save the new token to the variable cache for in-memory
        If ( $Script:variableCache.Keys -contains "access_token" ) {
            $Script:variableCache."access_token" = $token
        } else {
            $Script:variableCache.Add("access_token", $token )
        }


        #-----------------------------------------------
        # SAVE TOKEN TO FILE
        #-----------------------------------------------

        If ( $createNewToken -eq $true ) {

            If ( $Script:settings.token.encryptTokenFile -eq $true ) {
                $tokenPrepared = Convert-PlaintextToSecure -String $token
            } else {
                $tokenPrepared = $token
            }

            [PSCustomObject]@{
                "accesstoken" = $tokenPrepared
                "unixtime" = $validUntilUnixtime
                #"refreshtoken" = ""
            } | ConvertTo-Json | Set-Content -Path $Script:settings.token.tokenSettingsFile -Encoding utf8

        }


        #-----------------------------------------------
        # RETURN VALUE
        #-----------------------------------------------

        $token


    }

    end {

    }

}