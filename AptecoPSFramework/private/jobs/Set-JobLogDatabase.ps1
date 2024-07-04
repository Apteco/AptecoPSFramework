
Function Set-JobLogDatabase {
    [cmdletbinding()]
    param(
    )

    Process {

        # Resolve path first
        $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($script:settings.joblogDB)

        # Build Connection string
        $connString = "DataSource=$( $absolutePath )"

        # Add connection to duckdb
        Add-DuckDBConnection -Name "JobLog" -ConnectionString $connString

        # Open the connection
        Open-DuckDBConnection -Name "JobLog"
        
        # Create the database, if not exists
        $joblogCreateStatementPath = Join-Path -Path $Script:moduleRoot -ChildPath "sql/joblog_create.sql"
        $joblogCreateStatement = Get-Content -Path $joblogCreateStatementPath -Encoding UTF8 -Raw
        Invoke-DuckDBQueryAsNonExecute -Query $joblogCreateStatement -ConnectionName "JobLog"
    
    }

}