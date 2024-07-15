<#

https://developers.brevo.com/docs/fetch-all-your-weekly-marketing-events

Following process
This is an exclusive Brevo+ feature for gathering all of those events

{
'sent': 'requests',
'delivered': 'delivered',
'hard_bounce': 'hardBounces',
'soft_bounce': 'softBounces',
'click': 'clicks',
'open': 'opened',
'spam': 'spam',
'blocked': 'blocked',
'invalid': 'invalid',
'unsubscribe': 'unsubscribed',
'deferred': 'deferred',
'error': 'error',
'proxy_open': 'loadedByProxy',
'invalid_email': 'invalid'
}


curl --request POST \
     --url https://api.brevo.com/v3/webhooks/export \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data '
{
  "event": "allEvents",
  "type": "marketing",
  "days": 7
}
'

#>



function Add-ExportProcess {
    [CmdletBinding()]
    param (
         #[Parameter(Mandatory=$true)][String]$Name # TODO built in specific event names

        [Parameter(Mandatory=$false)]
        [ValidateSet("marketing", "transactional", IgnoreCase = $false)]
        [String]$Type = "marketing"             # marketing|transactional

        ,[Parameter(Mandatory=$false)][Int]$Days = 3 # max 7 days
    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "webhooks/export"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                "event"              = "allEvents"          # Must not be null, Must not contain padding whitespace characters, Size must be between 1 and 255 inclusive
                "type"       = $Type          # marketing|transactional
                "days" = $Days
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request lists
        $process = Invoke-Brevo @params

        # return
        #If ( $IncludeLinks -eq $true ) {
            $process
        #} else {
        #    $list | Select-Object * -ExcludeProperty "_links"
        #}

    }

    end {

    }

}

