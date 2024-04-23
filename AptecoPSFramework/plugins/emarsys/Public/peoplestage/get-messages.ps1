

function Get-Messages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
    )

    begin {


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "GETMESSAGES"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }

        #-----------------------------------------------
        # DEPENDENCIES
        #-----------------------------------------------

        #Import-Module MeasureRows
        #Import-Module SqlServer
        #Import-Module ConvertUnixTimestamp
        #Import-Lib -IgnorePackageStructure

        # Load SQLite library
        Add-Type -Path "$( $Script:pluginRoot )\lib\SQLite\System.Data.SQLite.dll"

        #Load Up PostGre libraries
        Add-Type -Path "$( $Script:pluginRoot )\lib\PostGre\Npgsql.dll"
        Add-Type -Path "$( $Script:pluginRoot )\lib\PostGre\Npgsql.NetTopologySuite.dll"

    }

    process {

        $mailings = [System.Collections.ArrayList]@()
        $mailings.AddRange($Script:settings.messageOptions)

        <#
        [void]$mailings.Add(
            [PSCustomObject]@{
                "id" = "a"
                "name" = "add"
            }
        )
        [void]$mailings.Add(
            [PSCustomObject]@{
                "id" = "r"
                "name" = "remove"
            }
        )
        #>

        # Load and filter list into array of mailings objects
        $mailingsList = [System.Collections.ArrayList]@()
        $mailings | ForEach-Object {
            $mailing = $_
            [void]$mailingsList.add(
                [Mailing]@{
                    mailingId=$mailing.id
                    mailingName=$mailing.name
                }
            )
        }

        # Transform the mailings array into the needed output format
        $columns = @(
            @{
                name="id"
                expression={ $_.mailingId }
            }
            @{
                name="name"
                expression={ $_.toString() }
            }
        )

        $messages = [System.Collections.ArrayList]@()
        [void]$messages.AddRange(@( $mailingsList | Select-Object $columns ))

        If ( $messages.count -gt 0 ) {

            Write-Log "Loaded $( $messages.Count ) messages" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No messages loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

        }

        # Return
        $messages

    }

    end {

    }

}



<#
#-----------------------------------------------
    # INITIATING A LOCAL DATABASE
    #-----------------------------------------------

    # Decide wether to use a local one or :memory:
    $tempDB = New-TemporaryFile # :memory:

    # Create the connection
    #$connString = "Data Source=""$( $sqliteFile )"";Version=3;New=$( $new );Read Only=$( $readonly );$( $additionalParameters )"
    $additionalParameters = "Journal Mode=MEMORY;Cache Size=-4000;Page Size=4096;"
    $dbConnectionString = "Data Source=""$( $tempDB )"";$( $additionalParameters )"
    $dbConnection = [System.Data.SQLite.SQLiteConnection]::new($dbConnectionString)


    #-----------------------------------------------
    # OPEN THE DATABASE
    #-----------------------------------------------

    $retries = 10
    $retrycount = 0
    $secondsDelay = 2
    $completed = $false

    while (-not $completed) {
        try {
            $dbConnection.open()
            Write-Host -message "Connection succeeded."
            $completed = $true
        } catch [System.Management.Automation.MethodInvocationException] {
            if ($retrycount -ge $retries) {
                Write-Host -message "Connection failed the maximum number of $( $retries ) times." -severity ([LogSeverity]::ERROR)
                throw $_
                exit 0
            } else {
                Write-Host -message "Connection failed $( $retrycount ) times. Retrying in $( $secondsDelay ) seconds." -severity ([LogSeverity]::WARNING)
                Start-Sleep -Seconds $secondsDelay
                $retrycount++
            }
        }
    }


    }

   #>

        <#
# Open the database connection
$connString = $settings.globalDB #"Host=myserver;Username=mylogin;Password=mypass;Database=mydatabase";
$conn = [Npgsql.NpgsqlConnection]::new($connString )
[void]$conn.OpenAsync()


$tries = 0
$maxTries = 10
Do {
    If ($tries -gt 0 ) {
        Start-Sleep -Milliseconds 500
        Write-Host "Another try"
    }
    $tries += 1
} Until ( $conn.State -eq "Open" -or $tries -eq $maxTries)

If ( $conn.State -ne "Open" ) {
    # TODO [ ] ERROR
    Write-Warning "Connection not opened"
}

$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT * FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

# load data
$datatable = [System.Data.DataTable]::new()
$sqlResult = $cmd.ExecuteReader()
$datatable.Load($sqlResult, [System.Data.Loadoption]::Upsert)
$sqlResult.close()
$cmd.Dispose()

$conn.Close()
#>