

function Invoke-SFSCQuery {

<#
    .SYNOPSIS
        Executes a SOQL query against Salesforce.

    .DESCRIPTION
        This function executes a SOQL query against Salesforce using either the direct query method or the bulk query method.
        It allows specifying whether to include attributes in the result, return the count of records, or use the queryAll option for bulk queries.

    .PARAMETER Query
        The SOQL query to execute.

    .PARAMETER Bulk
        Switch to use bulk query instead of a direct query.

    .PARAMETER IncludeAttributes
        Switch to include attributes in the result for direct queries.

    .PARAMETER ReturnCount
        Switch to return the count of records instead of the records themselves for direct queries.

    .PARAMETER QueryAll
        Switch to use the queryAll option for bulk queries.

    .EXAMPLE
        Invoke-SFSCQuery -Query "SELECT Id, Name FROM Account" -IncludeAttributes

    .EXAMPLE
        Invoke-SFSCQuery -Query "SELECT Id FROM Contact WHERE LastName LIKE 'A%'" -ReturnCount

    .EXAMPLE
        Invoke-SFSCQuery -Query "SELECT Id, Name FROM Lead" -Bulk -QueryAll

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        System.Object. The function returns the result of the SOQL query.

    .NOTES
        Author: florian.von.bracht@apteco.de
#>

    [CmdletBinding(DefaultParameterSetName = 'Direct')]
    param (

         [Parameter(Mandatory=$True, ParameterSetName = 'Direct')]
         [Parameter(Mandatory=$True, ParameterSetName = 'Bulk')]
         [String]$Query

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Bulk')]
         [Switch]$Bulk = $false

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Direct')]
         [Switch]$IncludeAttributes = $false

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Direct')]
         [Switch]$ReturnCount = $false

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Bulk')]
         [Switch]$QueryAll = $false

    )

    begin {

    }
    process {

        $queryObj = [PSCustomObject]@{
            "q" = $Query
        }

        Write-Log -severity verbose -Message "Executing query:"
        Write-Log -severity verbose -Message "  $( $Query.replace("`r`n"," ").replace("`n"," ").replace("`r"," ") )"

        If ( $Bulk -eq $true ) {

            $bulkPath = Join-Path -Path $Env:tmp -ChildPath "$( [guid]::newguid().ToString() ).csv"

            Write-Log "Writing results to '$( $bulkPath )'"

            $bulkParams = [Hashtable]@{
                "Query" = $Query                
                "Path" = $bulkPath
            }
            If ( $QueryAll -eq $True ) {
                $bulkParams.Add("QueryOperation", "queryAll")
            } else {
                $bulkParams.Add("QueryOperation", "query")
            }
            $return = Add-BulkJob @bulkParams

        } else {

            $result = Invoke-SFSC -Service "data" -Object "query" -Query $queryObj -Method "Get"
            <#
            $result = [PSCustomObject]@{
                "totalSize" = 10
                "done" = $true
                "records" = [Array]@(
                    [PSCustomObject]@{
                        Id = "a"
                        Name = "asdfasd"
                    }
                    [PSCustomObject]@{
                        Id = "b"
                        Name = "gdfgfg"
                    }
                )
            }
            #>
        

            #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers

            #return
            Write-Log -severity verbose -Message "Result:"
            Write-Log -severity verbose -Message "  Status: $( $result.done ) "
            Write-Log -severity verbose -Message "  Records: $( $result.totalSize ) "

            #$result #| where-object { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru

            # return
            $return = $null
            If ( $ReturnCount -eq $true ) {
                $return = $result.totalSize
            } else {
                If ( $IncludeAttributes -eq $true ) {
                    $return = $result.records
                } else {
                    $return = $result.records | Select-Object * -ExcludeProperty attributes
                }
            }

        }

        $return

    }

    end {

    }

}