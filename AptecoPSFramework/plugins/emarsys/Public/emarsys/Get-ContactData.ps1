




function Get-ContactData {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)][String[]]$KeyValues
        ,[Parameter(Mandatory=$false)][String]$KeyId = "email" # Identifies the contact by their id, uid, or the name/integer id of a custom field, such as email
        ,[Parameter(Mandatory=$false)][Array]$Fields = @("id","email")
        ,[Parameter(Mandatory=$false)][Switch]$ResolveFields = $false
        ,[Parameter(Mandatory=$false)][Switch]$IgnoreErrors = $false

    )

    begin {

        # build object for call
        $params = [Hashtable]@{
            "Object" = "contact"
            "Method" = "POST"
            "Path" = "getdata"
            "Body" = [PSCustomObject]@{
                'fields' = $Fields
                'keyId' = $KeyId
                'keyValues' = $null
            }
        }

        # add verbose flag, if set
        If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
            $params.Add("Verbose", $true)
        }

        $arr = [System.Collections.ArrayList]@()
        $total = 0
        $i = 0

    }

    process {

        # Support for parameter input
        foreach ($KeyValue in $KeyValues) {

            [void]$arr.Add($KeyValue)
            $i += 1
            $total += 1

            Write-Verbose "Added at i $( $i ) and total $( $total ) of $( $KeyValues.Count )"

            # Request list creation every n
            If ( $i % 1000 -eq 0 ) {

                Write-Verbose "Calling emarsys at i $( $i ) and total $( $total ) of $( $KeyValues.Count )"

                # Get the data from emarsys
                $params.Body.keyValues = $arr
                $fetchList = Invoke-EmarsysCore @params

                # Rewrite result
                If ( $ResolveFields -eq $true  ) {

                    $rewriteParams = [Hashtable]@{
                        "FetchList" = $fetchList
                        "IgnoreErrors" = $IgnoreErrors
                    }
                    Resolve-ContactData @rewriteParams

                } else {

                    If ( $IgnoreErrors -eq $true ) {
                        $fetchList.result
                    } else {
                        $fetchList
                    }

                }

                # Empty the cached values
                $arr.Clear()
                $i = 0

            }

        }

    }

    end {

        # Get a last call if there is something left
        If ( $i -gt 0 ) {

            Write-Verbose "Calling emarsys at i $( $i ) and total $( $total ) of $( $KeyValues.Count )"

            # Get the data from emarsys
            $params.Body.keyValues = $arr
            $fetchList = Invoke-EmarsysCore @params

            # Rewrite result
            If ( $ResolveFields -eq $true  ) {

                $rewriteParams = [Hashtable]@{
                    "FetchList" = $fetchList
                    "IgnoreErrors" = $IgnoreErrors
                }
                Resolve-ContactData @rewriteParams

            } else {

                If ( $IgnoreErrors -eq $true ) {
                    $fetchList.result
                } else {
                    $fetchList
                }
                
            }

            # Empty the cached values
            $arr.Clear()
            $i = 0

        }

    }

}


