

function Get-SFSCObjectData {

    <#
        .SYNOPSIS
            Retrieves data from a specified Salesforce object.
    
        .DESCRIPTION
            This function queries data from a specified Salesforce object using the Salesforce API.
            It allows specifying fields to retrieve, conditions for filtering, and limits on the number of records.
    
        .PARAMETER Object
            The Salesforce object to query data from.
    
        .PARAMETER Fields
            The fields to retrieve from the Salesforce object. If not specified, all fields are retrieved.
    
        .PARAMETER Where
            The conditions to filter the records. This should be a valid SOQL WHERE clause.
    
        .PARAMETER Limit
            The maximum number of records to retrieve. If set to -1, all records are retrieved.
    
        .PARAMETER IncludeAttributes
            Switch to include attributes in the result.
    
        .PARAMETER Bulk
            Switch to use bulk query instead of a direct query
    
        .EXAMPLE
            Get-SFSCObjectData -Object 'Account' -Fields 'Id', 'Name' -Where "Name LIKE 'A%'" -Limit 10
    
        .EXAMPLE
            Get-SFSCObjectData -Object 'Contact' -IncludeAttributes
    
        .EXAMPLE
            Get all fields from the Lead object and return the first 100 records
    
            Get-SFSCObjectData -Object "Lead" -Limit 100 -Verbose
    
        .EXAMPLE
            Get-SFSCObjectData -Object "Lead" -Fields id, firstname, lastname -Limit 100 -Bulk -Verbose
    
        .INPUTS
            None. You cannot pipe objects to this function.
    
        .OUTPUTS
            System.Object. The function returns the queried data from the Salesforce object.
    
        .NOTES
            Author: florian.von.bracht@apteco.de
    #>
    
    
    
    
        [CmdletBinding()]
        param (

             [Parameter(Mandatory=$true)]
             [String] $Object

            ,[Parameter(Mandatory=$false)]
             [String[]] $Fields = [Array]@()

            ,[Parameter(Mandatory=$false)]
             [String] $Where = ""

            ,[Parameter(Mandatory=$false)]
             [int] $Limit = 100

            ,[Parameter(Mandatory=$false)]
             [Switch] $IncludeAttributes = $False

            ,[Parameter(Mandatory=$false)]
             [Switch] $Bulk = $false
    
        )
    
        begin {
    
        }
        process {
    
            # curl https://MyDomainName.my.salesforce.com/services/data/v58.0/query/?q=SELECT+name+from+Account -H "Authorization: Bearer token"
    
            # Get all fields, when the parameter is not filled
            # ELSE use the specified fields
            If ( $fields.count -eq 0 ) {
    
                # Get all fields
                $fieldsResult = Get-SFSCObjectField -Object $Object
                $fieldList = $fieldsResult.name -join ", "
    
            } else {
    
                $fieldList = $Fields -join ", "
    
            }
    
            #$query = "SELECT $( $fieldList ) FROM $( $Object ) LIMIT $( $limit )"
    
            $queryBuilder = [System.Text.StringBuilder]::new()
            [void]$queryBuilder.AppendLine("SELECT $( $fieldList )")
            [void]$queryBuilder.AppendLine(" FROM $( $Object )")
    
            If ( $Where -ne "" ) {
                [void]$queryBuilder.AppendLine(" WHERE $( $Where )")
            }
            
            If ($Limit -ne -1) {
                [void]$queryBuilder.AppendLine(" LIMIT $( $limit )")
            }
    
            $resultParams = [Hashtable]@{
                "Query" = $queryBuilder.toString()
            }

            If ( $Bulk -eq $True ) {
                $resultParams.Add("Bulk", $True)
            } else {
                $resultParams.Add("IncludeAttributes", $IncludeAttributes)
            }
            
            #return
            @( Invoke-SFSCQuery @resultParams )
    
        }
    
        end {
    
        }
    
    }