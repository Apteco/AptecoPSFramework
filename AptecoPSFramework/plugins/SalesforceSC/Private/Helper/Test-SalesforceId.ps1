

function Test-SalesforceId {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String] $SalesforceId
    )

    process {

        #-----------------------------------------------
        # CHECK THE ID
        #-----------------------------------------------

        If ( $SalesforceId.Length -eq 18 ) {
            If ( $SalesforceId.Substring(3,3) -eq $Script:settings.instanceId ) {
                $true
            } else {
                $false
            }
        } else {
            $false
        }

    }

}



