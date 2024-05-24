
function Get-CustomFieldValue {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId
        [Parameter(Mandatory=$false)][Switch] $IncludeLinks = $false


    )

    begin {
        $resource = "fieldValues"
    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        # TODO maybe use DuckDB to reformat these values to columns

        $fields = Invoke-AC -Resource $resource -Paging

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        If ( $IncludeLinks -eq $true ) {
            $fields.$resource
        } else {
            $fields.$resource | Select-Object * -ExcludeProperty "links"
        }

    }

    end {

    }

}


