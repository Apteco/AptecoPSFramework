

function New-Tag {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String] $Name
        ,[Parameter(Mandatory=$true)][String] $Description
        #[Parameter(Mandatory=$true)][Int] $ListId

    )

    begin {

    }

    process {


        #$query = [PSCustomObject]@{"orders[id]"="ASC"}

        $body = [PSCustomObject]@{
            "tag" = [PSCustomObject]@{
                "tag" = $Name
                "tagType" = "contact"               # template|contact
                "description" = $Description
            }
        }
        

        $newTag = Invoke-AC -Resource "tags" -Method POST -Body $body

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        $newTag.tag

    }

    end {

    }

}


