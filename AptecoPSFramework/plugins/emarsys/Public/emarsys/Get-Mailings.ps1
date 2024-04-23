

function Get-Mailings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
    )

    begin {

        Invoke-EmarsysLogin

    }

    process {

        

    }

    end {

    }

}


