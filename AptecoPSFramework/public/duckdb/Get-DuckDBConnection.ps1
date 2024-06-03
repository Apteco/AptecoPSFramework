
Function Get-DuckDBConnection {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$false)][String]$Name = ""
            ,[Parameter(Mandatory=$false)][Switch]$All = $false
        )
        
        # TODO separate the two parameters in different sets as you can only do the one or the other
        
        Process {

            If ( $All -eq $false ) {

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

            } else {

                # If -All is set, just return all connections

                $conn = $Script:duckDb

            }

            # return
            $conn

        }


    }