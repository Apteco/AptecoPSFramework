
function Get-Account {
    [CmdletBinding()]
    param (
        
    )

    begin {

    }

    process {

        $params = [Hashtable]@{
            "Object" = "account"
            "Method" = "GET"
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $account = Invoke-Brevo @params

        $account

    }

    end {

    }

}

