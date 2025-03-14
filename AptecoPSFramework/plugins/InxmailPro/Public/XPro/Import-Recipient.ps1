
function Import-Recipient {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$false)]
        [ValidateSet("STANDARD", "ADMIN", "SYSTEM", IgnoreCase = $false)]
        [Array]$Type = [Array]@()             # STANDARD|ADMIN|SYSTEM - multiple values are allowed
        ,[Parameter(Mandatory=$false)][Switch]$All = $false  # Should the links also be included?
        ,[Parameter(Mandatory=$false)][Switch]$IncludeLinks = $false  # Should the links also be included?
    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "lists"
            "Method" = "GET"
            #"PageSize" = 100
            #"Paging" = $true
        }

        # Add paging
        If ( $All -eq $true ) {
            $params.Add("Paging", $true)
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request lists
        $lists = Invoke-XPro @params

        # Exclude mailings
        If ( $Type.Count -gt 0 ) {
            $listsToFilter = $lists."_embedded"."inx:lists" | Where-Object { $_.type -in $type }
        } else {
            $listsToFilter = $lists."_embedded"."inx:lists"
        }

        # return
        If ( $IncludeLinks -eq $true ) {
            $listsToFilter
        } else {
            $listsToFilter | Select-Object * -ExcludeProperty "_links"
        }

    }

    end {

    }

}


