


function Remove-SFSCObjectData {

<#
    .SYNOPSIS
        Removes data from Salesforce objects without Bulk API

    .DESCRIPTION
        This function removes data from Salesforce objects using the Salesforce API.
        It allows you to specify the object type and the data to be removed.

    .EXAMPLE
        Remove-SFSCObjectData

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        System.Object. The function returns a list of Salesforce objects.

    .NOTES
        Author: florian.von.bracht@apteco.de
#>

    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$True)]
         [String]$Object

        ,[Parameter(Mandatory=$True)]
         [String]$Id

    )

    process {

        $del = Invoke-SFSC -Service "data" -Object "sobjects" -Path "$( $Object )/$($Id)" -Method "Delete"

        #return
        $del

<#
curl -X DELETE https://yourInstance.salesforce.com/services/data/vXX.X/sobjects/Account/RECORD_ID \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
  #>

    }

}

