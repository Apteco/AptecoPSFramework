
function Get-Message {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {
        $resource = "messages"
    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        $messages = Invoke-AC -Resource $resource -Query $query

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $messages.$resource

    }

    end {

    }

}


