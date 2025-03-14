
function Remove-List {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Int[]]$Id
    )
    begin {

    }

    process {

        ForEach ($listId in $Id) {

            # Create params
            $params = [Hashtable]@{
                "Object" = "lists"
                "Method" = "DELETE"
                "Path" = $listId
            }

            # add verbose flag, if set
            If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
                $params.Add("Verbose", $true)
            }

            # Request lists
            $list = Invoke-XPro @params

            # return
            $list

        }

    }

    end {

    }

}


