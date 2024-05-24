
function Get-Event {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {
        $resource = "eventTrackingEvents"
    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        $events = Invoke-AC -Resource $resource

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $events.$resource

    }

    end {

    }

}


