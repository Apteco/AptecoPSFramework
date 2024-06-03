
Function Get-DuckDBConnection {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$false)][String]$Name = ""
        )

        Process {

            $searchFor = $Name
            If ( $searchFor -eq "" ) {
                $searchFor = "Default"
            }

            # Get the connection
            $conn = @( $Script:duckDb | Where-Object { $_.name -eq $searchFor } )

            # Check if the connection exists
            If ( $conn.count -ne 1 ) {
                throw "There is no connection with name '$( $searchFor )'"
            }

            # return
            $conn

        }


    }