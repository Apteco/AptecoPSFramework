
Function Open-DuckDBConnection {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$false)][String]$Name = ""
            # TODO also allow use other connection strings as input parameter?
        )

        Process {

            #-----------------------------------------------
            # ADD DEFAULT CONNECTION
            #-----------------------------------------------

            $defaultName = "Default"

            # If the name is empty and no connection used yet, add the default connection
            If ( $Name -eq "" -and ( $Script:duckDb | Where-Object { $_.name -eq $defaultName } ).Count -eq 0  ) {
                Add-DuckDBConnection -Name $defaultName -ConnectionString $Script:settings.defaultDuckDBConnection
            }


            #-----------------------------------------------
            # OPEN THE CONNECTION
            #-----------------------------------------------

            If ( $Name -eq "" ) {
                $conn = Get-DuckDBConnection
            } else {
                $conn = Get-DuckDBConnection -Name $Name
            }

            # Handle the connection state
            If ( $conn.connection.State -eq "Open" ) {

                throw "The connection named '$( $conn.name )' to '$( $conn.connection.ConnectionString )' is already opened"

            } elseif ( $conn.connection.State -eq "Closed" ) {

                # Open the connection with the default name
                Write-Log "Opening DuckDB connection named '$( $conn.name )' to '$( $conn.connection.ConnectionString )'" -Severity INFO
                try {
                $conn.connection.Open()
                } catch {
                    Write-Log -Message $_.exception -Severity ERROR
                }
            } else {

                throw "The connection named '$( $conn.name )' to '$( $conn.connection.ConnectionString )' has a different state than open or closed"

            }


        }


    }