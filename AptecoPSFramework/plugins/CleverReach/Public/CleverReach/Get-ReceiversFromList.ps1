# Source is the first part of the Tag, so apteco.a1qhvh3_20230607201732 split in "apteco" as source and "a1qhvh3_20230607201732" as tag

function Get-ReceiversFromList {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$true)][Int] $ListId
        ,[Parameter(Mandatory=$false)][Int] $Detail = 0
    )

    begin {

    }
    process {

        # TODO possibly use array rather than single tag

        # Prepare inactives query as security net
        $filterBody = [PSCustomObject]@{
            "groups" = [Array]@(,$ListId)
            "operator" = "AND"
            "rules" = [Array]@()
            "orderby" = "activated desc"
            "detail" = $Detail
        }

        $receiversWithTag = [Array]@( Invoke-CR -Object "receivers" -Path "filter.json" -Method POST -Paging -Body $filterBody ) # .PsObject.Copy() use a copy so the reference is not changed because it will used a second time

        $receiversWithTag

    }

    end {

    }

}



