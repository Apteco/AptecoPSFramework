
function Add-List {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Name
        ,[Parameter(Mandatory=$false)][String]$Description = ""
        ,[Parameter(Mandatory=$false)][String]$KeyId = "email" # Identifies the contact by their id, uid, or the name/integer id of a custom field, such as email
    )

    begin {

        If ($Name.Length -gt 0) {
            # Everythings ok
        } else {
            throw "Name is not valid"
        }

        If ($KeyId.Length -gt 0) {
            # Everythings ok
        } else {
            throw "KeyId is not valid"
        }

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "contactlist"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                "key_id" = $KeyId
                "name" = $Name
                "external_ids" = [System.Collections.ArrayList]@()  # Add an empty array
            }
        }

        # Add description, if defined
        If ( $Description.length -gt 0 ) {
            $params.body | Add-Member -MemberType NoteProperty -Name "description" -Value $Description
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list creation
        $newList = Invoke-EmarsysCore @params #-Object "field" -Path "translate/de"

        # return
        $newList

    }

    end {

    }

}


