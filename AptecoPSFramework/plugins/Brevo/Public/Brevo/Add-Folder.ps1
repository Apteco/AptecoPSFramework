function Add-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$Name
    )

    process {
        # Create params
        $params = @{
            "Object" = "contacts/folders"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                "name" = $Name.Trim()  # Must not be null, must not contain padding whitespace, size 1-100
            }
        }

        # add verbose flag, if set
        if ($PSBoundParameters["Verbose"].IsPresent -eq $true) {
            $params.Add("Verbose", $true)
        }

        # Request folder creation
        $folder = Invoke-Brevo @params

        # return
        $folder
    }
}