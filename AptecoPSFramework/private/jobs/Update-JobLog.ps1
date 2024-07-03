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
         ,[Parameter(Mandatory=$false)][Int]$DebugMode = 0          # Debug mode like 0 or 1
         ,[Parameter(Mandatory=$false)][String]$Type = ""       # Type like UPLOAD, MESSAGES, LISTS etc.
         ,[Parameter(Mandatory=$false)][String]$Input = ""      # Input hashtable
         ,[Parameter(Mandatory=$false)][Int]$Inputrecords = 0   # Number of records that have been put in
         ,[Parameter(Mandatory=$false)][Int]$Successful = 0     # Successful records, only needed on uploads
         ,[Parameter(Mandatory=$false)][Int]$Failed = 0         # Failed records, only needed on uploads
         ,[Parameter(Mandatory=$false)][Int]$Totalseconds = 0   # Seconds in total, logged at the end
         ,[Parameter(Mandatory=$false)][String]$Output = ""     # Output hashtable (if it is suitable)
    )

    Process {

        $sb = [System.Text.StringBuilder]::new()
        $sb.Append("UPDATE joblog SET ")

        $upd = [System.Collections.ArrayList]@()
        [void]$upd.Add("finished = $( $Finished )")
        [void]$upd.Add("status = '$( $Status )'")
        #[void]$upd.Add("process = '$( $Process )'")
        [void]$upd.Add("plugin = '$( $Plugin )'")
        [void]$upd.Add("debug = $( $DebugMode )")
        [void]$upd.Add("type = '$( $Type )'")
        [void]$upd.Add("input = '$( $Input )'")
        [void]$upd.Add("inputrecords = $( $Inputrecords )")
        [void]$upd.Add("successful = $( $Successful )")
        [void]$upd.Add("failed = $( $Failed )")
        [void]$upd.Add("totalseconds = $( $Totalseconds )")
        [void]$upd.Add("output = '$( $Output )'")
        $params = $upd -join ", "
        $sb.Append($params)

        $sb.Append("WHERE id = $( $JobId )")

        #$query = "update logjob set process = 'abc' where id = $( $JobId )"
        Invoke-DuckDBQueryAsNonExecute -Query $sb.ToString() -ConnectionName "JobLog"

    }


}