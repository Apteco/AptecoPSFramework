
function Get-Recurring {
    [CmdletBinding(DefaultParameterSetName = 'OnePage')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
        # [Parameter(Mandatory=$true, ParameterSetName = 'AllPages')]
         [Int] $Id

        ,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')]
         [Parameter(Mandatory=$false, ParameterSetName = 'AllPages')]
         [DateTime]$StartMin = [datetime]::MinValue

        ,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')]
         [Parameter(Mandatory=$false, ParameterSetName = 'AllPages')]
         [DateTime]$NextMin = [datetime]::MinValue

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
                    "Object" = "recurrings/$( $Id )"
                    "Method" = "GET"
                    "Paging" = $False
                }

                break
            }

            # All pages
            'AllPages' {

                $params = [Hashtable]@{
                    "Object" = "recurrings"
                    "Method" = "GET"
                    "Paging" = $True
                }

                If ( $NextMin -ne [datetime]::MinValue ) {
                    $params.Add( "Query", [PSCustomObject]@{"next_min"=$NextMin.toString("yyyy-MM-dd HH:mm:ss")} )
                }

                If ( $StartMin -ne [datetime]::MinValue ) {
                    $params.Add( "Query", [PSCustomObject]@{"next_min"=$StartMin.toString("yyyy-MM-dd HH:mm:ss")} )
                }

                break
            }

            # Single page
            Default {

                $params = [Hashtable]@{
                    "Object" = "recurrings"
                    "Method" = "GET"
                    "Paging" = $False
                    "Pagesize" = $First
                }

                If ( $NextMin -ne [datetime]::MinValue ) {
                    $params.Add( "Query", [PSCustomObject]@{"next_min"=$NextMin.toString("yyyy-MM-dd HH:mm:ss")} )
                }

                If ( $StartMin -ne [datetime]::MinValue ) {
                    $params.Add( "Query", [PSCustomObject]@{"next_min"=$StartMin.toString("yyyy-MM-dd HH:mm:ss")} )
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
        $recurrings = Invoke-FrBox @params

        # return
        $recurrings

    }

    end {

    }

}


