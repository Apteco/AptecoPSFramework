




function Get-Field {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][String] $LanguageId = ""
    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "field"
            "Method" = "GET"
        }

        # Handle language id
        If ( $LanguageId -ne "" ) {
            $params.Add("Path", "translate/$( $LanguageId )")
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request fields
        $fields = Invoke-EmarsysCore @params #-Object "field" -Path "translate/de"

        # return
        $fields

    }

    end {

    }

}


