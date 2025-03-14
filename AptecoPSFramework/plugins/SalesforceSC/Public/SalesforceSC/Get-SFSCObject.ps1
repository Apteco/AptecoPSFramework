


function Get-SFSCObject {

<#
    .SYNOPSIS
        Retrieves a list of Salesforce objects.

    .DESCRIPTION
        This function retrieves a list of Salesforce objects using the Salesforce API.
        The list includes information about each object available in the Salesforce instance.

    .EXAMPLE
        Get-SFSCObject

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        System.Object. The function returns a list of Salesforce objects.

    .NOTES
        Author: florian.von.bracht@apteco.de
#>

    [CmdletBinding()]
    param (
    )

    process {

        $objects = Invoke-SFSC -Object "sobjects" -Method "Get"

        #return
        $objects.sobjects

    }

}

