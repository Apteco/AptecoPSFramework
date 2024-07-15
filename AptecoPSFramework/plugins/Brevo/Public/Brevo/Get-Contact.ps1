
function Get-Contact {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$Id

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Int]$ListId = 0        
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Switch]$IncludeStats = $false  # Include stats for receiver

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
                If ( $IncludeStats -eq $true ) {
                    $statsParams = [Hashtable]@{
                        "Object" = "contacts"
                        "Method" = "GET"
                        "Path" = "$( $Id )/campaignStats"
                    }
                }

                break
            }

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "contacts"
                    "Method" = "GET"
                }

                # Change if it should only be from a list
                If ( $ListId -gt 0 ) {
                    $params = [Hashtable]@{
                        "Object" = "contacts/lists"
                        "Method" = "GET"
                        "Path" = "$( $ListId )/contacts"
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

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $contacts = Invoke-Brevo @params

        # Return
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # return
                If ( $IncludeStats -eq $true ) {
                    $stats = Invoke-Brevo @statsParams
                    $contacts | Add-Member -MemberType NoteProperty -Name "campaignStats" -Value $stats
                }

                $contacts

                break
            }

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $contacts
                } else {
                    $contacts.contacts
                }
                
                break
            }
        }

    }

    end {

    }

}

