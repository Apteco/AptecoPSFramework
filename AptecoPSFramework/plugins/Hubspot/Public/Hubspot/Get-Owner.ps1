
function Get-Owner {

    [CmdletBinding()]
    param (
        # [Parameter(Mandatory=$true)][String]$Object
        #,[Parameter(Mandatory=$false)][String[]]$PropertyName = ""
        #,[Parameter(Mandatory=$false)][Switch]$Archived = $false
        #,[Parameter(Mandatory=$false)][Switch]$IncludeObjectName = $false       # Include the object name like "contacts"

    )

    begin {

    }
    process {

        $owners = @( Invoke-Hubspot -Object "crm" -Path "owners" -Method GET )
        $owners.results        

    }

    end {

    }

}
