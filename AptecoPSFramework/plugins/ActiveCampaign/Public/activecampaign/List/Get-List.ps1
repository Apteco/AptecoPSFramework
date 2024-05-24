
function Get-List {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {
        $resource = "lists"
    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        $lists = Invoke-AC -Resource $resource -Query $query

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $lists.$resource

    }

    end {

    }

}


