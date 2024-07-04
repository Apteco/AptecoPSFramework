
Function Get-JobLog {
    <#

    ...
    # TODO maybe allow to show all jobs or since a specific job or something

    #>
    [cmdletbinding()]
    param(
         [Parameter(Mandatory=$true)][Int]$JobId
        ,[Parameter(Mandatory=$false)][Switch]$ConvertInputAsHashtable = $false
        #,[Parameter(Mandatory=$true)][String]$ConnectionString
        # TODO also allow use other connection strings as input parameter?
    )

    Process {

        # TODO check if connection is open?

        $job = Read-DuckDBQueryAsReader -Name "JobLog" -Query "SELECT * FROM joblog WHERE id = $( $JobId )" -ReturnAsPSCustom

        If ( $job.count -eq 0 ) {
            throw "No job found with id $( $JobId )"
        } elseif ( $job.count -gt 1 ) {
            throw "Multiple jobs found with id $( $JobId )"
        } else {

            If ( $ConvertInputAsHashtable -eq $true) {
                $job.input = ConvertFrom-JsonAsHashtable $job.input
            }

            # return
            $job
        }

    }

}