
function Add-List {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Name
        ,[Parameter(Mandatory=$true)][String]$SenderAddress
        ,[Parameter(Mandatory=$False)][String]$Description = ""
        ,[Parameter(Mandatory=$False)][String]$SenderName = ""
        ,[Parameter(Mandatory=$False)][String]$ReplyToName = ""
        ,[Parameter(Mandatory=$False)][String]$ReplyToAddress = ""
        ,[Parameter(Mandatory=$false)][Switch]$IncludeLinks = $false  # Should the links also be included?
    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "lists"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                "name"              = $Name.Trim()          # Must not be null, Must not contain padding whitespace characters, Size must be between 1 and 255 inclusive
                "description"       = $Description          # Size must be between 0 and 255 inclusive
                "type"              = "STANDARD"
                "senderAddress"     = $SenderAddress        # Must be a valid email address, Must not be null
            }
        }

        If ( $SenderName.Length -gt 0 ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "senderName" -Value $SenderName.Trim()    # Must not contain padding whitespace characters
        }

        If ( $ReplyToAddress.Length -gt 0 ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "replyToAddress" -Value $ReplyToAddress    # Must be a valid email address
        }

        If ( $ReplyToName.Length -gt 0 ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "replyToName" -Value $ReplyToName.Trim()    # Must not contain padding whitespace characters
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request lists
        $list = Invoke-XPro @params

        # return
        If ( $IncludeLinks -eq $true ) {
            $list
        } else {
            $list | Select-Object * -ExcludeProperty "_links"
        }

    }

    end {

    }

}


