
function Get-SegmentRecipient {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Collection')]
         [String]$ListId
        
        ,[Parameter(Mandatory=$true, ParameterSetName = 'Collection')]
         [String]$SegmentId
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$All = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$Expand = $false

    )

    begin {


    }

    process {

        switch ( $PSCmdlet.ParameterSetName ) {

            <#
            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "groups"
                    "Method" = "GET"
                    "Path" = "$( $Id )"
                }

                break
            }#>

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "lists"
                    "Method" = "GET"
                    "Path" = "$( $ListId )/groups/$( $SegmentId )/recipients"
                }

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                    $params.Add("PageSize", 5000 )#$Script:settings.pageSize)
                }
                
                break
            }

        }

        # Check expand
        If ( $Expand -eq $true ) {
            $params.Add("Query",[PSCustomObject]@{
                "_expand" = "true"
            })
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $recipients = Invoke-Sendinblue @params

        switch ($PSCmdlet.ParameterSetName) {
            
            <#
            'Single' {

                $segments.value

                break
            }
            #>

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $recipients
                } else {
                    $recipients.value
                }
                
                break
            }
        }

    }

    end {

    }

}

