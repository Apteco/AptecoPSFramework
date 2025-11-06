<#
$automations = @()
$result | where { $_.state -in $Script:settings.upload.automationStates } | foreach {

    # Load data
    $automation = $_
    #$campaign = $campaignDetails.elements.where({ $_.id -eq $mailing.campaignId })

    # Create mailing objects
    $automations += [OptilyzAutomation]@{automationId=$automation.'_id';automationName=$automation.name}

}
    #>

function Get-Automation {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [ValidateSet("live", "paused", IgnoreCase = $false)]
         [String]$State = "all"      # batch_email|transactional_email

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [String]$CreatedAt = ""                        # string like 2024-06-16

        ,[Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [Int]$Id

    )

    begin {
        
        $query = [Ordered]@{}
        $filter = [Array]@()
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "automations"
                    "Method" = "GET"
                    "Path" = $Id
                }

                break
            }

            'Collection' {

                # Just add the filter for automation state
                # TODO maybe implement the != operator
                switch ($State) {

                    "live" {
                        $filter.add("state==$( $State )")
                        break
                    }
                    "paused" {
                        $filter.Add("state==$( $State )")
                        break
                    }
                    default {

                    }

                }

                # Just add the filter for automation createdDate
                # TODO maybe implement the <, >, <= operator    
                If ( $CreatedAt -ne "" ) {
                    $f = [Datetime]::Today
                    If ( [Datetime]::TryParse($CreatedAt,[ref]$f) -eq $true ) {
                        $filter.add("createdAt>=$( $f.ToString("yyyy-MM-dd"))")
                    } else {
                        throw "CreatedAt is not valid"
                    }
                } else {
                    # Set nothing
                }

                # Create params
                $params = [Hashtable]@{
                    "Object" = "automations"
                    "Method" = "GET"
                }
                
                break
            }
        }

        # Add filters to query, if existing
        If ( $Filter.Count -gt 0 ) {
            $Query.Add("filter", ($filter -join ",")) # Add comma separated list of filters
        }

        # Add query, if existing
        If ( $Query.Count -gt 0 ) {
            $params.Add("Query", $query)
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $automation = Invoke-Optilyz @params

        # Return
        switch ($PSCmdlet.ParameterSetName) {
            
            'Single' {

                $automation

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $automation
                } else {
                    $automation #.templates
                }

                break
            }
        }

    }

    end {

    }

}

