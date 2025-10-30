
function Add-Webhook {
    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$true)]
         [String]$Url

         ,[Parameter(Mandatory=$true)]
         [String]$Bearer

         ,[Parameter(Mandatory=$false)]
          [ValidateSet("delivered", "opened", "click","hardBounce","softBounce","unsubscribed","contactUpdated","contactDeleted","listAddition","proxyOpen","spam")]
          [String[]]$Events = @("delivered", "opened", "click","hardBounce","softBounce","unsubscribed","contactUpdated","contactDeleted","listAddition","proxyOpen","spam")

    )

    begin {

    }

    process {

        # This could be more dynamic in the future to allow different webhook types with different authentication etc.

        # Create params
        $params = [Hashtable]@{
            "Object" = "webhooks"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                type    = "marketing"
                channel = "email"
                auth    = [PSCustomObject]@{
                    token = $Bearer #"your-static-secret-token-here"
                    type  = "bearer"
                }
                url     = $Url #"https://cloud.server.example/webhook/payload"
                batched = $true
                events  = @(
                    "delivered"
                    "opened"
                    "click"
                    "hardBounce"
                    "softBounce"
                    "unsubscribed"
                    "contactUpdated"
                    "contactDeleted"
                    "listAddition"
                    "proxyOpen"
                    "spam"
                )
            } 
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request lists
        $webhook = Invoke-Brevo @params

        # return
        $webhook

    }

    end {

    }

}

