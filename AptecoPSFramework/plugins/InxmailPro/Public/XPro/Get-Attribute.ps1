
function Get-Attribute {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$Id

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
                    "Object" = "attributes"
                    "Method" = "GET"
                    "Path" = $Id
                }

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "attributes"
                    "Method" = "GET"
                }

                # # Add paging
                # If ( $All -eq $true ) {
                #     $params.Add("Paging", $true)
                # }
                
                break
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request attributes
        $attributes = Invoke-XPro @params

        # Exclude mailings
        # If ( $Type.Count -gt 0 ) {
        #     $listsToFilter = $lists."_embedded"."inx:lists" | Where-Object { $_.type -in $type }
        # } else {
        #     $listsToFilter = $lists."_embedded"."inx:lists"
        # }

        # Return
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # return
                If ( $IncludeLinks -eq $true ) {
                    $attributes
                } else {
                    $attributes | Select-Object * -ExcludeProperty "_links"
                }

                break
            }

            'Collection' {

                # return
                If ( $IncludeLinks -eq $true ) {
                    $attributes."_embedded"."inx:attributes"
                } else {
                    $attributes."_embedded"."inx:attributes" | Select-Object * -ExcludeProperty "_links"
                }
                
                break
            }
        }

    }

    end {

    }

}


