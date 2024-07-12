
Function Close-JobLogDatabaseDatebase {
    <#

    ...

    #>
    [cmdletbinding()]
    param(
    )

    Process {

        Close-SqlConnection -ConnectionName "JobLog"

    }

}