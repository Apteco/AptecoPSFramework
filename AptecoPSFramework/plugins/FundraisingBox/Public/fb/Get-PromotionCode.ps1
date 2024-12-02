
function Get-PromotionCode {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "promotionCodes"
            "Method" = "GET"
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request fields
        $donations = Invoke-FrBox @params

        # return
        $donations

    }

    end {

    }

}


