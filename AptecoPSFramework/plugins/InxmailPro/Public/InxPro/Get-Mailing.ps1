
function Get-Mailing {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$false)]
        [ValidateSet("SUBSCRIPTION_TRIGGER_MAILING", "REGULAR_MAILING", IgnoreCase = $false)]
        [Array]$Type = [Array]@()             # SUBSCRIPTION_TRIGGER_MAILING|REGULAR_MAILING - multiple values are allowed

        ,[Parameter(Mandatory=$false)][Switch]$IncludeLinks = $false  # Should the links also be included?

    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "mailings"
            "Method" = "GET"
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request fields
        $mailings = Invoke-InxPro @params

        # Exclude mailings
        If ( $Type.Count -gt 0 ) {
            $mailingsToFilter = $mailings."_embedded"."inx:mailings" | Where-Object { $_.type -in $type }
        } else {
            $mailingsToFilter = $mailings."_embedded"."inx:mailings"
        }
        
        # return
        If ( $IncludeLinks -eq $true ) {
            $mailingsToFilter
        } else {
            $mailingsToFilter | Select-Object * -ExcludeProperty "_links"
        }


    }

    end {

    }

}


