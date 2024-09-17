function Get-SubscriptionPlan {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "subscription-plans"
            "Method" = "GET"
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $subscriptionPlan = Invoke-RaiseNow @params

        # Return
        $subscriptionPlan

    }

    end {

    }

}