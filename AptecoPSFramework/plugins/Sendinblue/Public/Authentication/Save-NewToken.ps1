

function Save-NewToken {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][String] $TokenSettingsFile
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $newToken = Request-NewToken
        $validUntilUnixtime = ( Get-Unixtime ) + [int]( $newToken.expires_in )
        $validUntilDatetime = ConvertFrom-UnixTime -Unixtime $validUntilUnixtime -ConvertToLocalTimezone
        Write-Log -message "Got new token valid until $( $validUntilDatetime.ToString("yyyy-MM-dd HH:mm:ss") )"

        # Save the new token to the variable cache for in-memory
        If ( $Script:variableCache.Keys -contains "sib_access_token" ) {
            $Script:variableCache."sib_access_token" = $newToken.access_token
            $Script:variableCache."sib_refresh_token" = $newToken.refresh_token
        } else {
            $Script:variableCache.Add("sib_access_token", $newToken.access_token )
            $Script:variableCache.Add("sib_refresh_token", $newToken.refresh_token )
        }

        # Create a blank file first, if it does not exist
        If ( (Test-Path -Path $Script:settings.token.tokenSettingsFile ) -eq $false ) {
            [PSCustomObject]@{
                "accesstoken" = ""
                "unixtime" = ""
                "refreshtoken" = ""
            } | ConvertTo-Json | Set-Content -Path $Script:settings.token.tokenSettingsFile -Encoding utf8
        }

        # And to a file so the token persits
        [void]( Request-TokenRefresh -SettingsFile $Script:settings.token.tokenSettingsFile -NewAccessToken $newToken.access_token -NewRefreshToken $newToken.refresh_token )

        # Return
        $newToken.access_token

    }

    end {

    }

}