
function Get-Me {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {

    }

    process {

        $me = Invoke-AC -Resource "users/me"

        # return
        $me.user

    }

    end {

    }

}


