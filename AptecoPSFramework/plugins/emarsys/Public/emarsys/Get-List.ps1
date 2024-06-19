
function Get-List {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "contactlist"
            "Method" = "GET"
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request fields
        $lists = Invoke-EmarsysCore @params #-Object "field" -Path "translate/de"

        # return
        $lists

    }

    end {

    }

}


