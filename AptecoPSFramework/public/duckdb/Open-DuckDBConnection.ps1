
Function Open-DuckDBConnection {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            # TODO also allow use other connection strings as input parameter?
        )

        Process {

            Write-Log "Opening DuckDB connection for: $( $Script:settings.defaultDuckDBConnection )" -Severity INFO
            $Script:duckDb = [DuckDB.NET.Data.DuckDBConnection]::new($Script:settings.defaultDuckDBConnection)

            $Script:duckDb.Open()

        }


    }