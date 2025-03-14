
Function Close-JobLogDatabase {
    <#

    ...

    #>
    [cmdletbinding()]
    param(
    )

    Process {

        # just try it
        try {
            Close-SqlConnection -ConnectionName "JobLog" -ErrorAction SilentlyContinue
        } catch {

        }

    }

}