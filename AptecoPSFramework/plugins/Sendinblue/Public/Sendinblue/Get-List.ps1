
function Get-List {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$Id
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Int]$FolderId = 0

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false

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
                    $params.Add("PageSize", 50)
                }
                
                break
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $lists = Invoke-Sendinblue @params

        # Return
        
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                $lists

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $lists
                } else {
                    $lists #.lists
                }

                break
            }
        }

    }

    end {

    }

}

