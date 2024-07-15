
Function Close-JobLogDatabase {
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