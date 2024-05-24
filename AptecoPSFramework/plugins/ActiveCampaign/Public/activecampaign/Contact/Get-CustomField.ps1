
function Get-CustomField {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {
        $resource = "fields"
    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        $fields = Invoke-AC -Resource $resource -Paging

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $fields.$resource

    }

    end {

    }

}


