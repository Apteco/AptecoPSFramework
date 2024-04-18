
function Get-Pipeline {

    [CmdletBinding()]
    param (
          [Parameter(Mandatory=$true)][String]$Object
        #,[Parameter(Mandatory=$false)][String[]]$PropertyName = ""
        #,[Parameter(Mandatory=$false)][Switch]$Archived = $false
        #,[Parameter(Mandatory=$false)][Switch]$IncludeObjectName = $false       # Include the object name like "contacts"

    )

    begin {

    }
    process {

        $pipelines = @( Invoke-Hubspot -Object "crm" -Path "pipelines/$( $Object )" -Method GET )
        $pipelines.results
    }

    end {

    }

}
