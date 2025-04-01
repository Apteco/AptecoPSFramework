

function Save-NewToken {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][String] $TokenSettingsFile
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        #$newToken = Register-NewTokenViaApi
        try {

            $newToken = Register-NewTokenViaOauth

            If ( $newToken -ne "" ) {

                Write-Log -message "Got new token valid for $( $newToken.expires_in ) seconds and scope '$( $newToken.scope )'" #-Verbose

                # Save the token and metadata around it
                [void]( Request-TokenRefresh -SettingsFile $Script:settings.token.tokenSettingsFile -NewAccessToken $newToken.access_token -NewRefreshToken $newToken.refresh_token )

                # Return
                $newToken.access_token

            }

        } catch {

            Write-Log -message "There was a problem with generating the token" -Severity ERROR

        }


        # Reset the logfile as it was changed by psoauth
        #Set-Logfile -Path $Script:settings.logfile

    }

    end {

    }

}