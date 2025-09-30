
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
            SimplySql\Close-SqlConnection -ConnectionName "JobLog" -ErrorAction SilentlyContinue
        } catch {

        }

    }

}