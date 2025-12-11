Function Update-JobLog {
    <#

    ...

    #>
    [CmdletBinding(DefaultParameterSetName = 'Hashtable')]
    param(

          [Parameter(Mandatory=$true, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$true, ParameterSetName = 'Array')]
          [Int]$JobId                # The Job ID that you have already got from the database

          # Values to change
         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [Switch]$Finished = $false   # Finished like 0 or 1

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [String]$Status = ""     # Status like "Finished" and others

         #,[Parameter(Mandatory=$false)][String]$Process = ""    # Process ID
         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [String]$Plugin = ""     # Plugin guid

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [Int]$DebugMode = -1          # Debug mode like 0 or 1

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [String]$Type = ""       # Type like UPLOAD, MESSAGES, LISTS etc.

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [Hashtable]$InputParam = [Hashtable]@{}      # Input hashtable

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [Int]$Inputrecords = -1   # Number of records that have been put in

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [Int]$Successful = -1     # Successful records, only needed on uploads

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [Int]$Failed = -1         # Failed records, only needed on uploads

         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')]
          [Parameter(Mandatory=$false, ParameterSetName = 'Array')]
          [Int]$Totalseconds = -1   # Seconds in total, logged at the end

         # Only one Output should be allowed
         ,[Parameter(Mandatory=$false, ParameterSetName = 'Hashtable')][Hashtable]$OutputParam = [Hashtable]@{}     # Output hashtable (if it is suitable)
         ,[Parameter(Mandatory=$false, ParameterSetName = 'Array')][System.Collections.ArrayList]$OutputArray = [System.Collections.ArrayList]@()     # Output array (if it is suitable)
    )

    Process {

        #-----------------------------------------------
        # CHECK CONNECTION
        #-----------------------------------------------

        Set-JobLogDatabase


        #-----------------------------------------------
        # BUILD THE STATEMENT
        #-----------------------------------------------

        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.Append("UPDATE joblog SET ")

        Write-Verbose "Checking parameters"

        $upd = [System.Collections.ArrayList]@()

        If ( $Finished -eq $true ) {
            Write-Verbose "Adding finished parameter"
            [void]$upd.Add("finished = $( $Finished )")
        }

        If ( $Status -ne "" ) {
            [void]$upd.Add("status = '$( $Status )'")
        }

        #[void]$upd.Add("process = '$( $Process )'")

        If ( $Plugin -ne "" ) {
            [void]$upd.Add("plugin = '$( $Plugin )'")
        }

        If ( $DebugMode -gt -1 ) {
            [void]$upd.Add("debug = $( $DebugMode )")
        }

        If ( $Type -ne "" ) {
            [void]$upd.Add("type = '$( $Type )'")
        }

        If ( $InputParam.Keys.Count -gt 0 ) {
            [void]$upd.Add("input = '$( ( ConvertTo-Json $InputParam -Depth 99 -Compress ) )'")
        }

        If ( $Inputrecords -gt -1 ) {
            [void]$upd.Add("inputrecords = $( $Inputrecords )")
        }

        If ( $Successful -gt -1 ) {
            [void]$upd.Add("successful = $( $Successful )")
        }

        If ( $Failed -gt -1 ) {
            [void]$upd.Add("failed = $( $Failed )")
        }

        If ( $Totalseconds -gt -1 ) {
            [void]$upd.Add("totalseconds = $( $Totalseconds )")
        }

        Switch ( $PSCmdlet.ParameterSetName ) {

            "Array" {
                If ( $OutputArray.Count -gt 0 ) {
                    [void]$upd.Add("output = '$( ( ConvertTo-Json $OutputArray -Depth 99 -Compress ) )'")
                }
                [void]$upd.Add("returnformat = 'ARRAY'")
            }

            default {
                If ( $OutputParam.Keys.Count -gt 0 ) {
                    [void]$upd.Add("output = '$( ( ConvertTo-Json $OutputParam -Depth 99 -Compress ) )'")
                }
                [void]$upd.Add("returnformat = 'HASHTABLE'")
                break
            }

        }

        $updateValues = $upd -join ", "
        [void]$sb.Append($updateValues)

        [void]$sb.Append("WHERE id = $( $JobId )")


        #-----------------------------------------------
        # UPDATE THE DATA
        #-----------------------------------------------

        #$query = "update logjob set process = 'abc' where id = $( $JobId )"
        #Invoke-DuckDBQueryAsNonExecute -Query $sb.ToString() -ConnectionName "JobLog"
        $sqlUpdate = SimplySql\Invoke-SqlUpdate -Query $sb.ToString() -ConnectionName "JobLog"


        #-----------------------------------------------
        # UPDATE THE DATA (with retry on busy/locked)
        #-----------------------------------------------

        $updateQuery = $sb.ToString()
        $maxRetries = 5
        $attempt = 0
        $delayMs = 200
        $sqlUpdate = $null

        while ($attempt -lt $maxRetries) {
            try {
                $attempt++
                $sqlUpdate = SimplySql\Invoke-SqlUpdate -Query $updateQuery -ConnectionName "JobLog" -ErrorAction Stop
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

    }


}