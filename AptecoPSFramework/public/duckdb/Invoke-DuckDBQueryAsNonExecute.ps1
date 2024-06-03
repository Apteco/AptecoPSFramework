
Function Invoke-DuckDBQueryAsNonExecute {
    <#

    ...

    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][String]$Query
        ,[Parameter(Mandatory=$false)][String]$ConnectionName = ""
    )

    Process {

        $conn = Get-DuckDBConnection -Name $ConnectionName
        $duckCommand = $conn.connection.createCommand()

        # Example: "Select count(*) from read_csv('C:\xyz.csv');"
        # You can define more options for loading csv through https://duckdb.org/docs/data/csv/overview
        $duckCommand.CommandText = $Query

        $result = $duckCommand.ExecuteNonQuery()

        # return as integer
        $result

    }

}