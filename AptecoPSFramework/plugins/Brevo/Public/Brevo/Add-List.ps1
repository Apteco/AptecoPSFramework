
function Add-List {
    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$true)]
         [String]$Name

        ,[Parameter(Mandatory=$false)]
         [Int]$FolderId = 1

    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "contacts/lists"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                "name"              = $Name.Trim()          # Must not be null, Must not contain padding whitespace characters, Size must be between 1 and 255 inclusive
                "folderId"       = $FolderId          # Size must be between 0 and 255 inclusive
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request lists
        $list = Invoke-Brevo @params

        # return
        #If ( $IncludeLinks -eq $true ) {
            $list
        #} else {
        #    $list | Select-Object * -ExcludeProperty "_links"
        #}

    }

    end {

    }

}

