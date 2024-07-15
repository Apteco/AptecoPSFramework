
function Get-Attribute {
    [CmdletBinding()]
    param (
        
    )

    begin {

    }

    process {

        $params = [Hashtable]@{
            "Object" = "contacts/attributes"
            "Method" = "GET"
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $attributes = Invoke-Brevo @params

        $attributes.attributes

    }

    end {

    }

}

