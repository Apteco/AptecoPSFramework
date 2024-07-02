
Function Read-DuckDBQueryAsReader {
    <#

    ...

    #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory=$true)][String]$Query
            ,[Parameter(Mandatory=$false)][String]$ConnectionName = ""
            ,[Parameter(Mandatory=$false)][Switch]$ReturnAsPSCustom = $false
            ,[Parameter(Mandatory=$false)][Switch]$AsStream = $false
        )

        Begin {

            $isSniffCsv = $false
            If ( $Query.Contains("sniff_csv") -eq $true ) {
                $isSniffCsv = $true
            }

            $conn = Get-DuckDBConnection -Name $ConnectionName
            $duckCommand = $conn.connection.createCommand()

            # Example: "Select * from read_csv('C:\Users\Florian\Downloads\example.txt', all_varchar = true, allow_quoted_nulls = true)"
            # You can define more options for loading csv through https://duckdb.org/docs/data/csv/overview

            # A good instant online example:
            # CREATE TABLE train_services AS FROM 's3://duckdb-blobs/train_services.parquet';
            # SELECT * FROM train_services LIMIT 10;
            $duckCommand.CommandText = $Query

            # Set streaming parameter, less RAM, possibly slower query, but the whole result is streamed rather than saved in one go
            If ( $AsStream -eq $true ) {
                $duckCommand.UseStreamingMode = $true
            }

            # Execute the reader
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
                If ( $AsStream -eq $false ) {
                    $returnPSCustomArrayList = [System.Collections.ArrayList]@()
                }
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
                    $returnPSCustom = [Ordered]@{}
                    For ($x = 0; $x -lt $reader.FieldCount; $x++ ) {
                        # TODO support other return types than string
                        if ($reader.IsDBNull($x) -eq $true ) {
                            $returnPSCustom[$reader.GetName($x)] = $null
                        } elseif ( $isSniffCsv -eq $true -and $reader.GetName($x) -eq "Columns" ) {
                            # This is a special subcollection
                            $subArrayList = [System.Collections.ArrayList]@()
                            $v = $reader.GetValue($x)
                            ForEach ( $y in $v ) {
                                $subPSCustom = [PSCustomObject]@{}
                                ForEach ($z in $y.Keys) {
                                    $subPSCustom | Add-Member -MemberType NoteProperty -Name $z -Value $y.$z
                                }
                                [void]$subArrayList.Add($subPSCustom)
                            }
                            $returnPSCustom[$reader.GetName($x)] = $subArrayList
                        } else {
                            $returnPSCustom[$reader.GetName($x)] = $reader.GetValue($x) #$reader.GetString($x)
                        }
                    }

                    If ( $AsStream -eq $true ) {
                        # return directly if it is a stream
                        [PSCustomObject]$returnPSCustom
                    } else {
                        # otherwise add to a collection
                        [void]$returnPSCustomArrayList.Add([PSCustomObject]$returnPSCustom)
                    }

                }

                # Return as collection in once, if not streaming
                If ( $AsStream -eq $false ) {
                    $returnPSCustomArrayList
                }

            } else {

                # TODO not quite what I was expecting, but PSCustomObject is more important for the start
                $reader

            }

        }

        End {

        }


    }