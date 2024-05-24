
function Get-Campaign {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {
        $resource = "campaigns"
    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        $campaigns = Invoke-AC -Resource $resource -Query $query

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $campaigns.$resource

    }

    end {

    }

}


