
function Get-Segment {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {
        $resource = "segments"
    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        $segments = Invoke-AC -Resource $resource -Query $query

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $segments.$resource

    }

    end {

    }

}


