




function Get-ListCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][Int] $ListId
    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "contactlist"
            "Path" = "$( $ListId )/count"
            "Method" = "GET"
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request fields
        $count = Invoke-EmarsysCore @params #-Object "field" -Path "translate/de"

        # return
        $count

    }

    end {

    }

}


