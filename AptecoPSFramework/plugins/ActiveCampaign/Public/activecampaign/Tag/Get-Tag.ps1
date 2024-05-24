
function Get-Tag {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId
        [Parameter(Mandatory=$false)][String] $Search = ""  # String to filter tag names, assumes contains
    )

    begin {
        $resource = "tags"
    }

    process {

        # To search for a tagname, use something like
        # https://aptecogmbh1715088391.api-us1.com/api/3/tags?search=My
        
        # Default query
        $query = [PSCustomObject]@{
            #"orders[id]"="ASC"
        }

        If ( $Search -ne "" ) {
            $query | Add-Member -MemberType NoteProperty -Name "search" -Value $Search
        }

        # Included deleted, if parameter is set -> deleted tags are automatically removed from resultset
        # If ( $IncludeDeleted -eq $false ) {
        #     $query | Add-Member -MemberType NoteProperty -Name "filters[deleted]" -Value "1"
        # }

        # Request tags
        $tags = Invoke-AC -Resource $resource -Query $query -Paging

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $tags.$resource | Where-Object { $_.deleted -eq 0 }

    }

    end {

    }

}


