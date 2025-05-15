


function Add-SFSCObjectData {

<#
    .SYNOPSIS
        Add data to Salesforce objects without Bulk API

    .DESCRIPTION
        This function adds data to Salesforce objects using the Salesforce API.
        It allows you to specify the object type and the data to be added.

    .EXAMPLE
        Add-SFSCObjectData

    .INPUTS
        Object and Attributes. Currently you cannot pipe objects to this function.

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
         [PSCustomObject]$Attributes

    )

    process {

        # TODO Add piping to this function

        $add = Invoke-SFSC -Service "data" -Object "sobjects" -Path "$( $Object )" -Method "Post" -Body $Attributes

        #return
        $add

<#
            curl -X POST https://yourInstance.salesforce.com/services/data/vXX.X/sobjects/Campaign/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "New Marketing Campaign",
    "Type": "Email",
    "Status": "Planned",
    "BudgetedCost": 5000,
    "ActualCost": 0
  }'
  #>

    }

}

