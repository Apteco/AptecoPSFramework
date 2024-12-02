
function Get-Mandate {
    [CmdletBinding(DefaultParameterSetName = 'OnePage')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
        # [Parameter(Mandatory=$true, ParameterSetName = 'AllPages')]
         [Int] $Id

        #,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')][Int] $SkipToken = 0
        ,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')][Int] $First = 10

        ,[Parameter(Mandatory=$false, ParameterSetName = 'AllPages')]
         [Switch] $All = $false

    )

    begin {

        # Create params

        Switch ( $PSCmdlet.ParameterSetName ) {

            # Single record
            'Single' {

                $params = [Hashtable]@{
                    "Object" = "mandates/$( $Id )"
                    "Method" = "GET"
                    "Paging" = $False    
                }

                break
            }

            # All pages
            'AllPages' {

                $params = [Hashtable]@{
                    "Object" = "mandates"
                    "Method" = "GET"
                    "Paging" = $True    
                }

                break
            }

            # Single page
            Default {

                $params = [Hashtable]@{
                    "Object" = "mandates"
                    "Method" = "GET"
                    "Paging" = $False
                    "Pagesize" = $First
                }
                
            }

        }

    }

    process {

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request fields
        $mandates = Invoke-FrBox @params

        # return
        $mandates

    }

    end {

    }

}

