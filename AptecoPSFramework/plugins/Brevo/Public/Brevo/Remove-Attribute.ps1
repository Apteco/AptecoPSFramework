function Remove-Attribute {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [ValidateSet("normal", "category", "transactional")]
        [String]$Category = "normal",

        [Parameter(Mandatory=$true)]
        [String]$Name
    )

    process {

        # Checking the name
        if ($Name -match '^[a-zA-Z0-9_]+$') {
            Write-Verbose "The attribute name '$( $Name )' is valid."
        } else {
            Throw "The attribute name '$( $Name )' is not valid. Only alphanumeric characters and underscores are allowed."
        }

        # Create params for DELETE request
        $params = @{
            "Object" = "contacts/attributes"
            "Path"   = "$( $Category )/$( $Name.ToUpper() )"
            "Method" = "DELETE"
        }

        # add verbose flag, if set
        if ($PSBoundParameters["Verbose"].IsPresent -eq $true) {
            $params.Add("Verbose", $true)
        }

        # Request attribute deletion
        $result = Invoke-Brevo @params

        # return
        $result

    }
}