
function Get-Property {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Object
        ,[Parameter(Mandatory=$false)][String[]]$PropertyName = ""
        ,[Parameter(Mandatory=$false)][Switch]$Archived = $false
        ,[Parameter(Mandatory=$false)][Switch]$IncludeObjectName = $false       # Include the object name like "contacts"

    )

    begin {

        $isSingleCall = $false
        If ( $PropertyName -ne "" ) {
            $isSingleCall = $true
        }

        $properties = [System.Collections.ArrayList]@()

    }
    process {

        $loadArchived = $false
        If ( $Archived -eq $true ) {
            $loadArchived = $true
        }

        # Single properties
        If ( $isSingleCall -eq $true ) {
            $PropertyName | ForEach-Object {
                $propName = $_
                $propData = Invoke-Hubspot -Object "crm" -Path "properties/$( $Object )/$( $propName )" -Method GET
                #Write-Host $propData
                [void]$properties.add( $propData )
            }
            $return = $properties

        # All properties
        } else {
            [void]$properties.Add( ( Invoke-Hubspot -Object "crm" -Path "properties/$( $Object )" -Query ([PSCustomObject]@{"archived"=$loadArchived}) -Method GET ))
            $return = $properties.results
        }

        If ( $IncludeObjectName -eq $true ) {
            $return | Add-Member -MemberType NoteProperty -Name "object" -Value $Object
        }

        $return


    }

    end {

    }

}
