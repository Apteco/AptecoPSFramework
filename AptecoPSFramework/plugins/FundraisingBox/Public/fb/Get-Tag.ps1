
function Get-Tag {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "tags"
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


