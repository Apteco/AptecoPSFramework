
function Get-Account {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {
        $resource = "accounts"
    }

    process {

        $account = Invoke-AC -Resource $resource

        # return
        $account.$resource

    }

    end {

    }

}


