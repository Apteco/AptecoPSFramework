function Request-NewToken {
    [CmdletBinding()]
    param (
        # [Parameter(Mandatory=$false)][String]$SettingsFile = "./cleverreach_token_settings.json"
        #,[Parameter(Mandatory=$false)][String]$TokenFile = "./sendinblue.token"
        #,[Parameter(Mandatory=$false)][Switch]$UseStateToPreventCSRFAttacks = $false
    )

    begin {

    }

    process {

        # https://docs.newsletter2go.com/#db2b80e2-f37f-4d4d-80ee-a072aae691a9

        #-----------------------------------------------
        # OAUTH LOGIN / RETRIEVE ACCESS TOKEN
        #-----------------------------------------------

        $success = $false
        $authString = Convert-SecureToPlaintext -String $Script:settings.login.authkey
        $auth = [Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes( $authString ) )
        $authString = ""

        $headers = [Hashtable]@{
            "Authorization" = "Basic $( $auth )"
        }

        $tokenUri = "https://api.newsletter2go.com/oauth/v2/token"
        $contentType = "application/json"

        # try first with refresh token - valid for 1 month
        try {
            If ( ( Test-Path -Path $Script:settings.token.tokenSettingsFile ) -eq $true ) {
                $tokenSettings = Get-Content -Path $Script:settings.token.tokenSettingsFile -Encoding UTF8 -Raw | ConvertFrom-Json

                $body = [PSCustomObject]@{
                    "refresh_token" = $tokenSettings.refresh_token
                    "grant_type" = "https://nl2go.com/jwt"
                } | ConvertTo-Json -Depth 99

                $a = Invoke-RestMethod -Method POST -Uri $tokenUri -ContentType $contentType -Body $body -Headers $headers

                $success = $true

            }

        } catch {

        }

        # then try completely fresh
        If ( $success -eq $false ) {

            try {

                $body = [PSCustomObject]@{
                    "username" = $Script:settings.login.user
                    "password" = Convert-SecureToPlaintext -String $Script:settings.login.password
                    "grant_type" = "https://nl2go.com/jwt"
                } | ConvertTo-Json -Depth 99
                
                $a = Invoke-RestMethod -Method POST -Uri $tokenUri -ContentType $contentType -Body $body -Headers $headers

                $success = $true

            } catch {

                # If still no success throw an error
                throw "Failed to refresh/create new token"

            }

        }
        
        
        $a
        

        <#
        access_token  : __eyJ0eXAiOiJK...
        expires_in    : 7200
        token_type    : bearer
        scope         :
        refresh_token : __eyJ0eXAiOiJK...
        account_id    : djid8707
        type          : user
        #>


    }

    end {

    }
}