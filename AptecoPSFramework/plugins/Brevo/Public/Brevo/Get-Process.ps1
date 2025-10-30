# This is needed to monitor email reaction exports

function Get-Process {
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
                    "Object" = "processes"
                    "Method" = "GET"
                    "Path" = $Id
                }

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "processes"
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
        $processes = Invoke-Brevo @params

        # Return
        
        switch ($PSCmdlet.ParameterSetName) {
            
            'Single' {

                $processes

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $processes
                } else {
                    $processes.processes
                }
                

                break
            }
        }

    }

    end {

    }

}

