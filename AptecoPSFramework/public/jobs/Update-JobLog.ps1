Function Update-JobLog {
    <#

    ...

    #>
    [cmdletbinding()]
    param(

          [Parameter(Mandatory=$true)][Int]$JobId                # The Job ID that you have already got from the database

          # Values to change
         ,[Parameter(Mandatory=$false)][Switch]$Finished = $false   # Finished like 0 or 1
         ,[Parameter(Mandatory=$false)][String]$Status = ""     # Status like "Finished" and others
         #,[Parameter(Mandatory=$false)][String]$Process = ""    # Process ID
         ,[Parameter(Mandatory=$false)][String]$Plugin = ""     # Plugin guid
         ,[Parameter(Mandatory=$false)][Int]$DebugMode = -1          # Debug mode like 0 or 1
         ,[Parameter(Mandatory=$false)][String]$Type = ""       # Type like UPLOAD, MESSAGES, LISTS etc.
         ,[Parameter(Mandatory=$false)][Hashtable]$InputParam = [Hashtable]@{}      # Input hashtable
         ,[Parameter(Mandatory=$false)][Int]$Inputrecords = -1   # Number of records that have been put in
         ,[Parameter(Mandatory=$false)][Int]$Successful = -1     # Successful records, only needed on uploads
         ,[Parameter(Mandatory=$false)][Int]$Failed = -1         # Failed records, only needed on uploads
         ,[Parameter(Mandatory=$false)][Int]$Totalseconds = -1   # Seconds in total, logged at the end
         ,[Parameter(Mandatory=$false)][Hashtable]$OutputParam = [Hashtable]@{}     # Output hashtable (if it is suitable)
    )

    Process {

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
            [void]$upd.Add("input = '$( ( ConvertTo-Json $InputParam -Depth 99 ) )'")
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

        If ( $OutputParam.Keys.Count -gt 0 ) {
            [void]$upd.Add("output = '$( ( ConvertTo-Json $OutputParam -Depth 99 ) )'")
        }

        $updateValues = $upd -join ", "
        [void]$sb.Append($updateValues)

        [void]$sb.Append("WHERE id = $( $JobId )")


        #-----------------------------------------------
        # UPDATE THE DATA
        #-----------------------------------------------

        #$query = "update logjob set process = 'abc' where id = $( $JobId )"
        #Invoke-DuckDBQueryAsNonExecute -Query $sb.ToString() -ConnectionName "JobLog"
        Invoke-SqlUpdate -Query $sb.ToString() -ConnectionName "JobLog"

    }


}