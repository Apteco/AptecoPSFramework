

function Get-ApiUsage {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        # [Parameter(Mandatory=$true)][String]$Object
        [Parameter(Mandatory=$false)][Switch]$ForceRefresh = $false
    )

    begin {

    }
    process {

        # Create a call if usage is not filled yet
        #If ( $Script:variableCache.Keys -notcontains "api_rate_limit" ) {
            #$usage = @( Invoke-Hubspot -Object "account-info" -Path "api-usage/daily" -Method GET )
        #}

        # Do a simple API call to refresh the counts

        #https://api.hubapi.com/crm/v3/objects/contacts?limit=1&archived=false
        
        # Get current timestamp
        $unixtime = Get-Unixtime
        $resetAt = $unixtime - $Script:variableCache."api_rate_reset" 
        
        If ( $unixtime -eq $resetAt -or $resetAt -ge 0 -or $ForceRefresh -eq $true) {
            # This means it needs a current status and needs to be refreshed
            $f = Get-Field # TODO check if maybe another call should be better for this
        }

        # All good, just remove the minus   
        $resetAt = [Math]::Abs($resetAt)

        # Put a message on the console
        Write-Verbose "Remaining $( $Script:variableCache."api_rate_remaining" )/$( $Script:variableCache."api_rate_limit" ), reset in $( $resetAt ) seconds" #-verbose

        # Return
        $Script:variableCache.api_rate_remaining

    }

    end {

    }

}



