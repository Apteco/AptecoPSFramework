

         
function Get-Event {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Collection')]
         [String]$MailingId

        ,[Parameter(Mandatory=$true, ParameterSetName = 'Collection')]
         [ValidateSet("received_newsletter", "opened_newsletter", "clicked_newsletter", "unsubscribed_newsletter", "bounced_newsletter", "complained_newsletter", IgnoreCase = $false)]
         [String]$EventType             # adhoc|recurring|newsletter|onevent|testmail|multilanguage|broadcast - multiple values are allowed
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$Expand = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$All = $false

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Array]$Fields = [Array]@()

    )

    begin {

    }

    process {

        switch ( $PSCmdlet.ParameterSetName ) {

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "newsletters"
                    "Method" = "GET"
                    "Path" = "$( $MailingId )/reports/recipients"
                }

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                    $params.Add("PageSize", 5000 )#$Script:settings.pageSize)
                }
                

                break
            }

        }

        # Check EventType
        $params.Add("Query",[PSCustomObject]@{
            "_filter" = "$( $EventType )=contains=`"$( $MailingId )`"" #"$( $( $EventType ) )%253DCONTAINS%253D%22$( $MailingId )%22"
        })

        # Check expand
        If ( $Expand -eq $true ) {
            $params.Query | Add-Member -MemberType NoteProperty -Name "_expand" -Value "true"
        } else {
            $params.Query | Add-Member -MemberType NoteProperty -Name "_expand" -Value "false"
        }

        If ( $Fields.Count -gt 0 ) {
            $params.Query | Add-Member -MemberType NoteProperty -Name "_fields" -Value ( $Fields -join "," )
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $events = Invoke-Sendinblue @params

        switch ($PSCmdlet.ParameterSetName) {

            'Collection' {

                # return
                If ( $All -eq $true ) {
                    $events
                } else {
                    $events.value
                }
                break
            }

        }

    }

    end {

    }

}

