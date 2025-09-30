
Function Set-JobLogDatabase {
    [cmdletbinding()]
    param(
    )

    Process {

        <#
        # Build Connection string
        $connString = "DataSource=$( $absolutePath )"

        # Add connection to duckdb
        Add-DuckDBConnection -Name "JobLog" -ConnectionString $connString

        # Open the connection
        Open-DuckDBConnection -Name "JobLog"
        #>

        $connectDatabase = $true
        try {
            $c = SimplySql\Get-SqlConnection -ConnectionName "JobLog" -ErrorAction SilentlyContinue
            If ( $c.State -eq "Open" ) {
                $connectDatabase = $false
            }
        } catch {
            # Still connect here
        }

        If ( $connectDatabase -eq $true ) {

            # Resolve path first
            $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($script:settings.joblogDB)

            # Open the connection
            SimplySql\Open-SQLiteConnection -ConnectionName "JobLog" -DataSource $absolutePath

            # Create the database, if not exists
            $joblogCreateStatementPath = Join-Path -Path $Script:moduleRoot -ChildPath "sql/joblog_create.sql"
            $joblogCreateStatement = Get-Content -Path $joblogCreateStatementPath -Encoding UTF8 -Raw
            #Invoke-DuckDBQueryAsNonExecute -Query $joblogCreateStatement -ConnectionName "JobLog"

            $u = SimplySql\Invoke-SqlUpdate -ConnectionName "JobLog" -Query $joblogCreateStatement

        }

    }

}