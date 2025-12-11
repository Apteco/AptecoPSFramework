
# https://developers.brevo.com/reference/getemailcampaigns-1
# TODO Add a sort criteria - can be done in API for creation date, otherwise in PS
# TODO Add statistics parameter
function Get-Campaign {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [Int]$Id

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [ValidateSet("all", "classic", "trigger", IgnoreCase = $false)]
         [String]$Type = "all"      # batch_email|transactional_email

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [ValidateSet("all", "suspended", "archive", "sent", "queued", "draft", "inProcess", "inReview", IgnoreCase = $false)]
         [String]$Status = "all"      # batch_email|transactional_email

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$IncludeHtml = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [String]$StartDate = ""                        # string like YYYY-MM-DDTHH:mm:ss.SSSZ
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [String]$EndDate = ""                          # string like YYYY-MM-DDTHH:mm:ss.SSSZ

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$All = $false

    )

    begin {
        
        $query = [Ordered]@{}


        If ( $StartDate -ne "" ) {
            $f = [Datetime]::Today
            If ( [Datetime]::TryParse($StartDate,[ref]$f) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "StartDate" -Value $f.ToString("yyyy-MM-ddTHH:mm:ss.fff")
            } else {
                throw "StartDate is not valid"
            }
        } else {
            # Set nothing
        }


        If ( $EndDate -ne "" ) {
            $t = [Datetime]::Today
            If ( [Datetime]::TryParse($EndDate,[ref]$t) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "EndDate" -Value $t.ToString("yyyy-MM-ddTHH:mm:ss.fff")
            } else {
                throw "EndDate is not valid"
            }
        } else {
            # Set nothing
        }

    }

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "emailCampaigns"
                    "Method" = "GET"
                    "Path" = $Id
                }

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "emailCampaigns"
                    "Method" = "GET"
                }

                # Just add the filter for campaign type
                If ( $Type -ne "all" ) {
                    $query.Add("type", $Type)
                }

                # Just add the filter for campaign status
                If ( $Status -ne "all" ) {
                    $query.Add("status", $Status)
                }

                # Include HTML content
                If ( $IncludeHtml -eq $true ) {
                    $query.Add("excludeHtmlContent", "false")
                } else {
                    $query.Add("excludeHtmlContent", "true")
                }

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                    $params.Add("PageSize", 100)
                }
                
                break
            }
        }

        # Add query, if existing
        If ( $Query.Count -gt 0 ) {
            $params.Add("Query", [PSCustomObject]$query)
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $campaigns = Invoke-Brevo @params

        # Return
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                $campaigns

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $campaigns
                } else {
                    $campaigns.campaigns #| Select-Object -Property * -ExcludeProperty htmlContent
                }

                break
            }
        }

    }

    end {

    }

}

