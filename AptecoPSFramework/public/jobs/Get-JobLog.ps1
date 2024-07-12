
Function Get-JobLog {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    Param(

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$JobId

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Switch]$ConvertInputAsHashtable = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Switch]$ConvertOutputAsHashtable = $false

        #,[Parameter(Mandatory=$true)][String]$ConnectionString

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Int]$Last = 100  # Get the last n entries
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false  # Get all instead of last n

    )

    Process {

        # TODO check if connection is open?

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                #$job = Read-DuckDBQueryAsReader -Name "JobLog" -Query "SELECT * FROM joblog WHERE id = $( $JobId )" -ReturnAsPSCustom
                $job = Invoke-SqlQuery -Query "SELECT * FROM joblog WHERE id = $( $JobId )" -ConnectionName "JobLog" -Stream

                If ( $job.count -eq 0 ) {
                    throw "No job found with id $( $JobId )"
                } elseif ( $job.count -gt 1 ) {
                    throw "Multiple jobs found with id $( $JobId )"
                } else {

                    If ( $ConvertInputAsHashtable -eq $true) {
                        $job.input = ConvertFrom-JsonAsHashtable $job.input
                    }

                    If ( $ConvertOutputAsHashtable -eq $true) {
                        $job.output = ConvertFrom-JsonAsHashtable $job.output
                    }

                }

                break
            }

            'Collection' {

                $q = "SELECT * FROM joblog ORDER BY id DESC"

                # Add last page
                If ( $All -ne $true ) {
                    $q += " LIMIT $( $Last )"
                }

                #$job = Read-DuckDBQueryAsReader -Name "JobLog" -Query  -ReturnAsPSCustom
                $job = Invoke-SqlQuery -Query $q -ConnectionName "JobLog" -Stream

                $job | ForEach-Object {
                    $j = $_
                    $j.input = ConvertFrom-JsonAsHashtable $j.input
                    $j.output = ConvertFrom-JsonAsHashtable $j.input
                }

                break
            }
        }

        $job
        

    }

}