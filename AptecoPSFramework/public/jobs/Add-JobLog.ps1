
<#
If ( $isDuckDBLoaded -eq $true )

    # Resolve path first
    $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($script:settings.joblogDB)

    # Build Connection string
    $connString = "DataSource=$( $absolutePath )"

    # Add connection to duckdb
    Add-DuckDBConnection -Name "JobLog" -ConnectionString $connString

Incremental ID
Guid/ProcessID
Plugin
Debug Yes/No
JobType (Upload, Messages, Lists, Preview)
InputHashtable as JSON
InputRecordsCount
CreateDateTime
UpdateDateTime
FinishDateTime
TotalTime
output is the returned hashtable

Return an ID


CREATE TABLE IF NOT EXISTS joblog (
     id              INTEGER PRIMARY KEY
    ,created         TEXT DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime'))
    ,updated         TEXT
    ,finished        INTEGER
    ,status          TEXT
    ,process         TEXT
    ,plugin          TEXT
    ,debug           INTEGER
    ,type            TEXT
    ,input           TEXT
    ,inputrecords    INTEGER
    ,successful      INTEGER
    ,failed          INTEGER
    ,totalseconds    INTEGER
    ,output          TEXT
)

CREATE TRIGGER IF NOT EXISTS update_joblog_trigger
AFTER UPDATE On joblog
BEGIN
   UPDATE joblog SET updated = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime') WHERE id = NEW.id;
END;

And then allow to execute the job type


Then when creating a new row with
insert into joblog (status) values ('abc');
select last_insert_rowid()

you get back the id value

https://duckdb.org/docs/extensions/sqlite#writing-data-to-sqlite


INSERT INTO sqlite_db.tbl VALUES (42, 'DuckDB');


INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\Users\Florian\Downloads\a pet co\apetco.sqlite' AS apetco (TYPE sqlite);
use apetco;
select * from kontakte;
-- select * from duckdb_extensions();

#>


Function Add-JobLog {
    <#

    ...

    #>
    [cmdletbinding()]
    param(
        # [Parameter(Mandatory=$true)][String]$Guid
        #,[Parameter(Mandatory=$true)][String]$ConnectionString
        # TODO also allow use other connection strings as input parameter?
    )

    Process {

        Set-JobLogDatabase

        $maxRetries = 5
        $attempt = 0
        $delayMs = 200
        $return = $null

        while ($attempt -lt $maxRetries) {
            try {
                $attempt++
                    #SimplySql\Invoke-SqlScalar -ConnectionName "JobLog" -Query "INSERT INTO joblog (process) values ('$( $Script:processId )'); SELECT last_insert_rowid()"
                    $return = SimplySql\Invoke-SqlScalar -ConnectionName "JobLog" -Query "INSERT INTO joblog (process) values ('$( $Script:processId )'); SELECT id FROM joblog WHERE process = '$( $Script:processId )'" -ErrorAction Stop
                break
            } catch {
                $ex = $_.Exception
                if ($null -ne $ex -and $null -ne $ex.Message) {
                    $msg = $ex.Message.ToLowerInvariant()
                } else {
                    $msg = ''
                }

                if ($null -ne $ex) {
                    $typeName = $ex.GetType().FullName
                } else {
                    $typeName = ''
                }

                # treat SQLite busy/locked or sqlite-specific exceptions as transient
                # typically the message is "database is locked"
                if ($msg -match 'busy' -or $msg -match 'locked' -or $typeName -match 'sqlite') {
                    if ($attempt -lt $maxRetries) {
                        Start-Sleep -Milliseconds $delayMs
                        # exponential backoff, cap at 5s
                        $delayMs = [Math]::Min($delayMs * 2, 5000)
                        continue
                    }
                }

                # non-transient or out of retries -> rethrow
                throw
            }
        }

        $return

    }

}