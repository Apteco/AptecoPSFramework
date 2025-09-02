
function Get-Contact {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [String]$Id

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [String]$ListId = ""        
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$All = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$Expand = $false
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Array]$Fields = [Array]@()
                 
         <#
        ,[Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$IncludeStats = $false
        #>
    )

    begin {
        # https://github.com/sendinblue/APIv3-php-library/blob/master/docs/Api/ContactsApi.md#getcontacts
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "contacts"
                    "Method" = "GET"
                    "Path" = $Id
                }

                # Create params for second call
                <#
                If ( $IncludeStats -eq $true ) {
                    $statsParams = [Hashtable]@{
                        "Object" = "contacts"
                        "Method" = "GET"
                        "Path" = "$( $Id )/campaignStats"
                    }
                }
                #>

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "recipients/global"
                    "Method" = "GET"
                }

                # Change if it should only be from a list
                If ( $ListId -gt 0 ) {
                    $params = [Hashtable]@{
                        "Object" = "lists"
                        "Method" = "GET"
                        "Path" = "$( $ListId )/recipients"
                    }
                }

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                    $params.Add("PageSize", 5000)
                }
                
                break
            }
        }

        # Check expand
        If ( $Expand -eq $true ) {
            $params.Add("Query",[PSCustomObject]@{
                "_expand" = "true"
            })
        } else {
            $params.Add("Query",[PSCustomObject]@{
                "_expand" = "false"
            })
        }

        If ( $Fields.Count -gt 0 ) {
            $params.Query | Add-Member -MemberType NoteProperty -Name "_fields" -Value ( $Fields -join "," )
            <#
            $params.Add("Query",[PSCustomObject]@{
                "_fields" = $Fields -join ","
            })
            #>
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $contacts = Invoke-Sendinblue @params

        # Return
        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                # return
                If ( $Expand -eq $true ) {
                    #$stats = Invoke-Brevo @statsParams
                    #$contacts | Add-Member -MemberType NoteProperty -Name "campaignStats" -Value $stats
                }

                $contacts.value

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $contacts
                } else {
                    $contacts.value #.contacts
                }
                
                break
            }
        }

    }

    end {

    }

}

