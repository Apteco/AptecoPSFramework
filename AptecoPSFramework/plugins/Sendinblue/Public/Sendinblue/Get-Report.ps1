
function Get-Report {
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param (

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')]
         [String]$MailingId


    )

    begin {

    }

    process {

        switch ( $PSCmdlet.ParameterSetName ) {

            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "newsletters"
                    "Method" = "GET"
                    "Path" = "$( $MailingId )/reports"
                }

                break
            }

        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $mailings = Invoke-Sendinblue @params

        # Add mailing id        
        $mailings.value | Add-Member -MemberType NoteProperty -Name "id" -Value $MailingId

        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                $mailings.value

                break
            }

        }

    }

    end {

    }

}

