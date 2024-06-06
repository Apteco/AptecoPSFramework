
Function Add-DuckDBConnection {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
             [Parameter(Mandatory=$true)][String]$Name
            ,[Parameter(Mandatory=$true)][String]$ConnectionString
            # TODO also allow use other connection strings as input parameter?
        )

        Process {


            # Check that the connection not exists yet
            If ( ( $Script:duckDb | Where-Object { $_.name -eq $Name } ).Count -eq 0 ) {

                Write-Log "Adding DuckDB connection named '$( $Name )' to '$( $ConnectionString )'" -Severity INFO
                [void]$Script:duckDb.Add(
                    [PSCustomObject]@{
                        "name" = $Name
                        "connection" = [DuckDB.NET.Data.DuckDBConnection]::new($ConnectionString)
                    }

                )

            } else {

                throw "There is already a connection with the name '$( $name )'"

            }


        }


    }