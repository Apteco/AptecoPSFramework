function Get-Listrecipient {

    [CmdletBinding(DefaultParameterSetName = 'ContactList')]
    param (

		 [Parameter(Mandatory=$False, ParameterSetName = 'ContactId')]
		 [String]$ContactId

		,[Parameter(Mandatory=$False, ParameterSetName = 'ContactEmail')]
		 [String]$ContactEmail

		,[Parameter(Mandatory=$False, ParameterSetName = 'ContactList')]
		 [String]$ListId = ""

		,[Parameter(Mandatory=$False, ParameterSetName = 'ContactList')]
		 [bool]$IgnoreDeleted = $True

		,[Parameter(Mandatory=$False, ParameterSetName = 'ContactList')]
		 [Switch]$IsExcludedFromCampaigns = $False

		,[Parameter(Mandatory=$False, ParameterSetName = 'ContactList')]
		 [Switch]$Opened = $False

		,[Parameter(Mandatory=$False, ParameterSetName = 'ContactList')]
		 [Switch]$Unsub = $False

		,[Parameter(Mandatory=$False, ParameterSetName = 'ContactList')]
		 [Switch]$CountOnly = $False

    )

    begin {

    }
    process {

		# define parameters
		$params = [Hashtable]@{
			"Object" = "listrecipient"
			"Method" = "GET"
		}


        Switch ( $PSCmdlet.ParameterSetName ) {

			"ContactList" {

				$query = [Ordered]@{}

				If ( $ListId -ne "" ) {
					$query.Add("ContactsList", $ListId)
				}

				If ( $IsExcludedFromCampaigns -eq $True ) {
					$query.Add("IsExcludedFromCampaigns", $True)
				}

				If ( $Opened -eq $True ) {
					$query.Add("Opened", $True)
				}

				If ( $Unsub -eq $True ) {
					$query.Add("Unsub", $True)
				}

				break
			}

			"ContactId " {

				$query = [Ordered]@{}
				$query.Add("ContactId", $ContactId)
				$params.Add("Query", [PSCustomObject]$query)

				break
			}

			"ContactEmail " {

				$query = [Ordered]@{}
				$query.Add("ContactEmail", $ContactEmail)
				$params.Add("Query", [PSCustomObject]$query)

				break
			}

		}

		If ( $PSCmdlet.ParameterSetName -notin @("ContactId","ContactEmail" ) ) {
			If ( $CountOnly -eq $true) {

				# Count everything
				$query.Add("CountOnly", $true)

			} else {

				$params.Add("Paging", $true)

			}

			$params.Add("Query", [PSCustomObject]$query)

		}

		# add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

		# call Apteco email
		$listRecipients = Invoke-Ae @params

		<#
		This returns an object like

		Count : 10
		Data  : {@{Address=51mnity95; CreatedAt=2024-03-06T15:50:25Z; ID=277381; IsDeleted=False; Name=Test
				Template_20240306-165025; SubscriberCount=2}, @{Address=44jvkg5m2; CreatedAt=2024-03-07T08:45:54Z; ID=277842;
				IsDeleted=False; Name=Test Template_20240307-094554; SubscriberCount=2}, @{Address=7ou1umruj;
				CreatedAt=2024-03-07T09:58:27Z; ID=277899; IsDeleted=False; Name=09_Template_20240307-105827;
				SubscriberCount=1}, @{Address=6ikwtwmpn; CreatedAt=2024-03-07T11:09:46Z; ID=277972; IsDeleted=False;
				Name=09_Template_20240307-120946; SubscriberCount=1}...}
		Total : 10

		#>

		# return
        $listRecipients.Data #| Where-Object { $_.Name -like $Name }

    }

    end {

    }

}



