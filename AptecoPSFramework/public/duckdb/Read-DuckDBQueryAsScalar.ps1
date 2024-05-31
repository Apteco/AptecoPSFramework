
Function Read-DuckDBQueryAsScalar {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$true)][String]$Query
        )

        Process {

            $duckCommand = $Script:duckDb.createCommand()

            # Example: "Select count(*) from read_csv('C:\xyz.csv');"
            # You can define more options for loading csv through https://duckdb.org/docs/data/csv/overview
            $duckCommand.CommandText = $Query

            $count = $duckCommand.ExecuteScalar()

            # return as integer
            $count

        }


    }