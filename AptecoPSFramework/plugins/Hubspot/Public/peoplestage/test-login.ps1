﻿



function Test-Login {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
    )

    begin {


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "TESTLOGIN"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }


    }

    process {

        #-----------------------------------------------
        # CHECK CLEVERREACH CONNECTION
        #-----------------------------------------------

        try {

            $c = get-crmdata -Object contacts -Limit 1

        } catch {

            #$msg = "Failed to connect to CleverReach, unauthorized or token is expired"
            #Write-Log -Message $msg -Severity ERROR
            Write-Log -Message $_.Exception -Severity ERROR
            throw $msg
            exit 4

        }


        #-----------------------------------------------
        # STOP TIMER
        #-----------------------------------------------

        $processEnd = [datetime]::now
        $processDuration = New-TimeSpan -Start $processStart -End $processEnd
        Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"


        #-----------------------------------------------
        # RETURN VALUES TO PEOPLESTAGE
        #-----------------------------------------------

        # return object
        $return = [Hashtable]@{

            # General return value to identify this custom channel in the broadcasts detail tables
            "CustomProvider"= $moduleName
            "ProcessId" = $Script:processId

        }

        # log the return object
        Write-Log -message "RETURN:"
        $return.Keys | ForEach-Object {
            $param = $_
            Write-Log -message "    $( $param ) = '$( $return[$param] )'" -writeToHostToo $false
        }

        # return the results
        $return


    }

    end {

    }

}




