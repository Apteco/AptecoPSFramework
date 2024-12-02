
function Get-Donation {
    [CmdletBinding(DefaultParameterSetName = 'OnePage')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
        # [Parameter(Mandatory=$true, ParameterSetName = 'AllPages')]
         [Int] $Id

        ,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')]
         [Parameter(Mandatory=$false, ParameterSetName = 'AllPages')]
         [DateTime]$DateFrom = $null

        #,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')][Int] $SkipToken = 0
        ,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')]
        [Int] $First = 10

        ,[Parameter(Mandatory=$false, ParameterSetName = 'AllPages')]
         [Switch] $All = $false

    )


    begin {

        # Create params

        Switch ( $PSCmdlet.ParameterSetName ) {

            # Single record
            'Single' {

                $params = [Hashtable]@{
                    "Object" = "donations/$( $Id )"
                    "Method" = "GET"
                    "Paging" = $False    
                }

                break
            }

            # All pages
            'AllPages' {

                $params = [Hashtable]@{
                    "Object" = "donations"
                    "Method" = "GET"
                    "Paging" = $True
                }

                If ( $DateFrom -ne $null ) {
                    $params.Add( "Query", [PSCustomObject]@{"date_min"=$DateFrom.toString("yyyy-MM-dd HH:mm:ss")} )
                }

                break
            }

            # Single page
            Default {

                $params = [Hashtable]@{
                    "Object" = "donations"
                    "Method" = "GET"
                    "Paging" = $False
                    "Pagesize" = $First
                }

                If ( $DateFrom -ne $null ) {
                    $params.Add( "Query", [PSCustomObject]@{"date_min"=$DateFrom.toString("yyyy-MM-dd HH:mm:ss")} )
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
        $donations = Invoke-FrBox @params

        # return
        $donations

    }

    end {

    }

}


