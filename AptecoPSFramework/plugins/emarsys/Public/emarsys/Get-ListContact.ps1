




function Get-ListContact {
    [CmdletBinding(DefaultParameterSetName = 'OnePage')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'OnePage')]
         [Parameter(Mandatory=$true, ParameterSetName = 'AllPages')]
         [Int] $ListId

        ,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')][Int] $SkipToken = 0
        ,[Parameter(Mandatory=$false, ParameterSetName = 'OnePage')][Int] $Top = 10000

        ,[Parameter(Mandatory=$false, ParameterSetName = 'AllPages')]
         [Switch] $All = $false

    )

    begin {

        $res =  [System.Collections.ArrayList]@()

        if ($PSCmdlet.ParameterSetName -eq 'AllPages') {
            $SkipToken = 0
            $Top = 10000
        }

    }

    process {

        # Create params

        Do {

            $params = [Hashtable]@{
                "Object" = "contactlist"
                "Method" = "GET"
                "Path" = "$( $ListId )/contactIds"
                "Query" = [PSCustomObject]@{
                    '$skiptoken' = $SkipToken
                    '$top' = $Top
                }
            }
    
            # add verbose flag, if set
            If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
                $params.Add("Verbose", $true)
            }
    
            # Request list creation
            $fetchList = Invoke-EmarsysCore @params
            $res.AddRange($fetchList.value)
            
            # Setup next page
            If ( $fetchList.next -ne $null ) {
                $queryChar = $fetchList.next.IndexOf("?")
                $nextQueryParams = [System.Web.HttpUtility]::ParseQueryString($fetchList.next.Substring( $queryChar+1 ))
                $SkipToken = $nextQueryParams['$skiptoken']
                #$Top = $nextQueryParams['$top']
            }

        } While ( $All -eq $true -and $fetchList.next -ne $null )

        # return
        $res

    }

    end {

    }

}


