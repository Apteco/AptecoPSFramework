


function Get-SFSCToken {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {

        $oAuthIntrospect = Invoke-SFSC -Service "oauth2" -Object "introspect" -Method "Post"
        $oAuthIntrospect

    }

    end {

    }

}

