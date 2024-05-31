
Function Read-DuckDBQueryAsReader {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$true)][String]$Query
            ,[Parameter(Mandatory=$false)][Switch]$ReturnAsPSCustom = $false
        )

        Begin {

            # TODO check if all requisites are OK for streaming

            $duckCommand = $Script:duckDb.createCommand()

            # Example: "Select * from read_csv('C:\Users\Florian\Downloads\example.txt', all_varchar = true, allow_quoted_nulls = true)"
            # You can define more options for loading csv through https://duckdb.org/docs/data/csv/overview

            # A good instant online example:
            # CREATE TABLE train_services AS FROM 's3://duckdb-blobs/train_services.parquet';
            # SELECT * FROM train_services LIMIT 10;
            $duckCommand.CommandText = $Query

            $reader = $duckCommand.ExecuteReader()

            # return as [System.Data.Common.DbDataReader]
            #$reader

            <#

            Example of handling this, good example here: https://github.com/Giorgi/DuckDB.NET

            # Number of fields
            $reader.FieldCount

            # Name of field 2
            $reader.GetName(1)

            # Get value of field 2 as String
            $reader.GetString(1)

            #>

            If ( $ReturnAsPSCustom -eq $true ) {
                
                $returnPSCustomArrayList = [System.Collections.ArrayList]@()

            }

            # TODO implement as datatable

            <#
            $dt = [System.Data.Datatable]::new()
            [void]$dt.Columns.Add("First")
            [void]$dt.Columns.Add("Second")
            [void]$dt.Columns.Add("IDGAF")


            (1..250000).ForEach{    
                [void]$dt.Rows.Add($_, ($_ * 100), '0')
            }
            #>

        }

        Process {

            If ( $ReturnAsPSCustom -eq $true ) {
                
                While ($reader.read()) {

                    # Create object and fill it
                    $returnPSCustom = [PSCustomObject]@{}
                    For ($x = 0; $x -lt $reader.FieldCount; $x++ ) {
                        # TODO support other return types than string
                        if ($reader.IsDBNull($x) -eq $true ) {
                            $returnPSCustom | Add-Member -MemberType NoteProperty -Name $reader.GetName($x) -Value $null
                        } else {
                            $returnPSCustom | Add-Member -MemberType NoteProperty -Name $reader.GetName($x) -Value $reader.GetValue($x) #$reader.GetString($x)
                        }
                    }
                    [void]$returnPSCustomArrayList.Add($returnPSCustom)

                }

                $returnPSCustomArrayList

            } else {

                # TODO not quite what I was expecting, but PSCustomObject is more important for the start
                $reader

            }

        }

        End {

        }


    }