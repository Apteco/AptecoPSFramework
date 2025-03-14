




function Get-SFSCObjectMeta {
<#
    .SYNOPSIS
        Retrieves metadata for a specified Salesforce object.

    .DESCRIPTION
        This function retrieves metadata for a specified Salesforce object using the Salesforce API.
        The metadata includes information about the object's fields, relationships, and other properties.

    .PARAMETER Object
        The Salesforce object to retrieve metadata for.

    .EXAMPLE
        Get-SFSCObjectMeta -Object 'Account'

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        System.Object. The function returns the metadata of the specified Salesforce object.

    .NOTES
        Author: florian.von.bracht@apteco.de
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String] $Object
    )

    begin {

    }
    process {

        $meta = Invoke-SFSC -Service "data" -Object "sobjects" -Path "$( $Object )" -Method "Get"

        #return
        $meta.objectDescribe

    }

    end {

    }

}


