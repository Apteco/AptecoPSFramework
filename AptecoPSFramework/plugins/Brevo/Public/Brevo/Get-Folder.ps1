
function Get-Folder {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$Id
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false

    )

    begin {

    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "contacts/folders"
                    "Method" = "GET"
                    "Path" = $Id
                }

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "contacts/folders"
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
        $folders = Invoke-Brevo @params

        # Return
        
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                $folders

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $folders
                } else {
                    $folders.Folders
                }

                break
            }
        }

    }

    end {

    }

}

