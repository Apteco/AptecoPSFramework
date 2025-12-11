
# https://developers.brevo.com/reference/getsmtptemplates
# TODO Add a sort criteria - can be done in API for creation date, otherwise in PS
function Get-Campaign {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$Id
        
        ,[Parameter(Mandatory=$false)]
         [ValidateSet("all", "active", "inactive", IgnoreCase = $false)]
         [String]$TemplateStatus = "all"      # batch_email|transactional_email

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false

    )

    begin {
        
        $query = [Ordered]@{}

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
                    "Object" = "smtp/templates"
                    "Method" = "GET"
                }

                # Just add the filter for template status
                switch ($TemplateStatus) {

                    "active" {
                        $query.Add("templateStatus", "true")
                        break
                    }
                    "inactive" {
                        $query.Add("templateStatus", "false")
                        break
                    }
                    default {

                    }

                }

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                    $params.Add("PageSize", 1000)
                }
                
                break
            }
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
        $templates = Invoke-Brevo @params

        # Return
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                $templates

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $templates
                } else {
                    $templates.templates
                }

                break
            }
        }

    }

    end {

    }

}

