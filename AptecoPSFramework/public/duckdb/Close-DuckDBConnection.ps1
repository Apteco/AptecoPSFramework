
Function Close-DuckDBConnection {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$false)][String]$Name = ""
        )

        Process {

            # Get the connection
            If ( $Name -eq "" ) {
                $conn = Get-DuckDBConnection
            } else {
                $conn = Get-DuckDBConnection -Name $Name
            }

            # Handle the connection state
            If ( $conn.connection.State -eq "Open" ) {

                # Open the connection with the default name
                Write-Log "Closing DuckDB connection named '$( $conn.name )' to '$( $conn.connection.ConnectionString )'" #-Severity INFO

                $conn.connection.Close()

            } elseif ( $conn.connection.State -eq "Closed" ) {

                throw "The connection named '$( $conn.name )' to '$( $conn.connection.ConnectionString )' is already closed"

            } else {

                throw "The connection named '$( $conn.name )' to '$( $conn.connection.ConnectionString )' has a different state than open or closed"

            }

        }

    }