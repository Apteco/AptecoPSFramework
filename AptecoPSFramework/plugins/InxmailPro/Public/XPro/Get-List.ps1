
function Get-List {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$Id

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [ValidateSet("STANDARD", "ADMIN", "SYSTEM", IgnoreCase = $false)]
         [Array]$Type = [Array]@()             # STANDARD|ADMIN|SYSTEM - multiple values are allowed
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false  # Should the links also be included?
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$IncludeLinks = $false  # Should the links also be included?

    )

    begin {

    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "lists"
                    "Method" = "GET"
                    "Path" = $Id
                }

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "lists"
                    "Method" = "GET"
                }

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                }
                
                break
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $lists = Invoke-XPro @params

        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # return
                If ( $IncludeLinks -eq $true ) {
                    $lists
                } else {
                    $lists | Select-Object * -ExcludeProperty "_links"
                }

                break
            }

            'Collection' {

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
                
                break
            }
        }

    }

    end {

    }

}


