
Function Read-DuckDBQueryAsReader {
    <#
    
    ...
    
    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$true)][String]$Query
        )
    
        Process {
    
            $duckCommand = $Script:duckDb.createCommand()

            # Example: "Select * from read_csv('C:\Users\Florian\Downloads\example.txt', all_varchar = true, allow_quoted_nulls = true)"
            # You can define more options for loading csv through https://duckdb.org/docs/data/csv/overview
            $duckCommand.CommandText = $Query

            $reader = $duckCommand.ExecuteReader()

            # return as [System.Data.Common.DbDataReader]
            $reader

            <#
            
            Example of handling this, good example here: https://github.com/Giorgi/DuckDB.NET

            # Number of fields
            $reader.FieldCount
            
            # Name of field 2
            $reader.GetName(1)

            # Get value of field 2 as String
            $reader.GetString(1)
            
            #>
    
        }
    
    
    }