function Get-Campaigns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Switch] $Launched = $false
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
    )

    begin {

        Invoke-EmarsysLogin

    }

    process {

         #| Out-GridView -PassThru | Select -first 20
# $fields | Out-GridView
# #$fields | Export-Csv -Path ".\fields.csv" -Encoding Default -NoTypeInformation -Delimiter "`t"
# #$fields | Select @{name="field_id";expression={ $_.id }}, @{name="fieldname";expression={$_.name}} -ExpandProperty choices | Export-Csv -Path ".\fields_choices.csv" -Encoding Default -NoTypeInformation -Delimiter "`t"

# $c = Invoke-emarsys -cred $cred -uri "$( $settings.base )field/translate/de" -method Get

        # TODO remove this later
        $stringSecure = ConvertTo-SecureString -String ( Convert-SecureToPlaintext $Script:settings.login.secret ) -AsPlainText -Force
        $cred = [pscredential]::new( $Script:settings.login.username, $stringSecure )

        #$emarsys = $Script:variableCache.emarsys

        # Change parameters
        If ( $Launched -eq $true ) {
            $launchedParam = 1
        } else {
            $launchedParam = 0
        }

        # List email campaigns
        $campaigns = Invoke-emarsys -cred $cred -uri "$( $Script:settings.base )email/launched=$( $launchedParam )&fromdate=2023-02-22" -method GET #-body $body
        #$campaigns.Count

        # Choose email campaign
        #$campaign = $campaigns | where { $_.status -in @('3','-3') } | where { $_.name -like "*Deu – Pflicht – Willkommen*" } | Out-GridView -PassThru
        #$campaign = $campaigns | where { $_.status -eq '-3' } | Out-GridView -PassThru
        #$campaign = $campaigns | where { $_.id -eq '10558554' }

        $campaigns

    }

    end {

    }

}


