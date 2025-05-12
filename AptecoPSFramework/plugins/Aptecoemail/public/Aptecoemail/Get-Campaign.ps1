



function Get-Campaign {

    [CmdletBinding(DefaultParameterSetName = 'List')]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$false)][String] $Name = "*"

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Message')]
         [String]$CampaignId = ""

        ,[Parameter(Mandatory=$False, ParameterSetName = 'Message')]
         [ValidateSet("Transactional", "Marketing", "Unknown", "All", IgnoreCase = $false)]
         [String]$FromType = "All"

       ,[Parameter(Mandatory=$False, ParameterSetName = 'Message')]
        [Switch]$ShowSubject = $False

       ,[Parameter(Mandatory=$False, ParameterSetName = 'List')]
        [String]$ListId


    )

    begin {

    }
    process {

		# define parameters
		$params = [Hashtable]@{
			"Object" = "campaign"
			"Method" = "GET"
			#"Pagesize" = 2
			"Paging" = $true
		}

		# add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

		# call Apteco email
		$campaigns = Invoke-Ae @params

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
        $campaigns.Data | Where-Object { $_.Name -like $Name }

    }

    end {

    }

}



