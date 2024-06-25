




function Get-HealthStatus {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][String] $LanguageId = ""
    )

    begin {

    }

    process {

        # Request fields
        #$status = Invoke-EmarsysCore @params #-Object "field" -Path "translate/de"
        $status = Invoke-RestMethod -Uri "https://api.emarsys.net/healthcheck" -Method GET

        # return
        $status

    }

    end {

    }

}


