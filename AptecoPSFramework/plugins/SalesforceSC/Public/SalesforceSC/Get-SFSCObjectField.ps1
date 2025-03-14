




function Get-SFSCObjectField {
<#
    .SYNOPSIS
        Retrieves field metadata for a specified Salesforce object.

    .DESCRIPTION
        This function retrieves field metadata for a specified Salesforce object using the Salesforce API.
        The metadata includes information about the fields of the object.

    .PARAMETER Object
        The Salesforce object to retrieve field metadata for.

    .EXAMPLE
        Get-SFSCObjectField -Object 'Account'

    .EXAMPLE
        Get-SFSCObjectField -Object "CampaignMember" | where-object { $_.createable -eq $True }

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        System.Object. The function returns the field metadata of the specified Salesforce object.

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


        $fields = Invoke-SFSC -Service "data" -Object "sobjects" -Path "$( $Object )/describe/" -Method "Get"

        #return
        $fields.fields

    }

    end {

    }

}


