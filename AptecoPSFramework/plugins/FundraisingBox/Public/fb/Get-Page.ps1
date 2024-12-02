
function Get-Page {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "pages"
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


