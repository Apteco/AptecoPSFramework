﻿

function Get-Tags {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $tags = @( Invoke-CR -Object "tags" -Query ([PSCustomObject]@{"group_id"=0;"order_by"="count";limit=5000}) -Method GET -Paging ) # use a copy so the reference is not changed because it will used a second time

        $tags

    }

    end {

    }

}



