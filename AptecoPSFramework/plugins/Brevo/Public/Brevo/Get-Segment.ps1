
function Get-Segment {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param ( 
        
        [Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false

    )

    begin {
        # https://github.com/sendinblue/APIv3-php-library/blob/master/docs/Api/ContactsApi.md#getcontacts
    }

    process {

        

        # Create params
        $params = [Hashtable]@{
            "Object" = "contacts"
            "Method" = "GET"
            "Path" = "segments"
        }

        # Add paging
        If ( $All -eq $true ) {
            $params.Add("Paging", $true)
            $params.Add("PageSize", 50)
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $segments = Invoke-Brevo @params

        # Return
        $segments.segments

    }

    end {

    }

}

