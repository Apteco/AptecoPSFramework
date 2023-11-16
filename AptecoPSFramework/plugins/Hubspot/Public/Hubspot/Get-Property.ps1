
function Get-Property {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$true)][String]$Object
        ,[Parameter(Mandatory=$false)][Switch]$Archived = $false
        ,[Parameter(Mandatory=$false)][Switch]$IncludeObjectName = $false       # Include the object name like "contacts"

    )

    begin {

    }
    process {

        $loadArchived = $false
        If ( $Archived -eq $true ) {
            $loadArchived = $true
        }

        $properties = @( Invoke-Hubspot -Object "crm" -Path "properties/$( $Object )" -Query ([PSCustomObject]@{"archived"=$loadArchived}) -Method GET )

        If ( $IncludeObjectName -eq $true ) {
            $properties.results | Add-Member -MemberType NoteProperty -Name "object" -Value $Object
        }
        $properties.results

    }

    end {

    }

}
