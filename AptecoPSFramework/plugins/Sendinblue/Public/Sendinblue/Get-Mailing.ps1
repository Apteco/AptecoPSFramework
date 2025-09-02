
function Get-Mailing {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [String]$Id

        ,[Parameter(Mandatory=$true, ParameterSetName = 'Collection')]
         [String]$ListId
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$All = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$Expand = $false

    )

    begin {

    }

    process {

        switch ( $PSCmdlet.ParameterSetName ) {

            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "newsletters"
                    "Method" = "GET"
                    "Path" = "$( $Id )"
                }

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "lists"
                    "Method" = "GET"
                    "Path" = "$( $ListId )/newsletters"
                }

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                    $params.Add("PageSize", $Script:settings.pageSize)
                }
                
                break
            }

        }

        # Check expand
        If ( $Expand -eq $true ) {
            $params.Add("Query",[PSCustomObject]@{
                "_expand" = "true"
            })
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $mailings = Invoke-Sendinblue @params

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                $mailings.value

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $mailings
                } else {
                    $mailings.value
                }
                
                break
            }
        }

    }

    end {

    }

}

