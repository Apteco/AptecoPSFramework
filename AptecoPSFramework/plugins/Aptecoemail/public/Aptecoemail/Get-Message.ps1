



function Get-Message {

    [CmdletBinding(DefaultParameterSetName = 'Message')]
    param (

		 [Parameter(Mandatory=$False, ParameterSetName = 'Message')]
		 [String]$CampaignId = ""

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Message')]
         [ValidateSet("Transactional", "Marketing", "Unknown", "All", IgnoreCase = $false)]
         [String]$FromType = "All"

		,[Parameter(Mandatory=$False, ParameterSetName = 'Message')]
		 [Switch]$ShowSubject = $False

		,[Parameter(Mandatory=$False, ParameterSetName = 'Contact')]
		 [String]$ContactId

		,[Parameter(Mandatory=$False, ParameterSetName = 'Message')]
		 [Switch]$CountOnly = $False

    )

    begin {

    }
    process {

		# define parameters
		$params = [Hashtable]@{
			"Object" = "message"
			"Method" = "GET"

		}

        Switch ( $PSCmdlet.ParameterSetName ) {

			"Message" {

				$query = [Ordered]@{}

				If ( $CampaignId -ne "" ) {
					$query.Add("Campaign", $CampaignId)
				}

				If ( $FromType -ne "All" ) {
					$query.Add("FromType", $FromType)
				}

				If ( $ShowSubject -eq $true ) {
					$query.Add("ShowSubject", $true)
				}

				break
			}

			"Contact " {

				$query = [Ordered]@{}
				$query.Add("ContactId", $ContactId)
				$params.Add("Query", [PSCustomObject]$query)

				break
			}

		}

		If ( $PSCmdlet.ParameterSetName -notin @( "Contact" ) ) {
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
		$messages = Invoke-Ae @params

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
        $messages.Data #| Where-Object { $_.Name -like $Name }

    }

    end {

    }

}



