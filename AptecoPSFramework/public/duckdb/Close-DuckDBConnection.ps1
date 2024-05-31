
Function Close-DuckDBConnection {
    <#

    ...

    #>
        [cmdletbinding()]
        param(

        )

        Process {

            $Script:duckDb.Close()

        }


    }