function Add-Attribute {
    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$true)]
         [String]$Name

        ,[Parameter(Mandatory=$true)]
         [ValidateSet("text", "date", "float", "id", "boolean")]
         [String]$Type

        ,[Parameter(Mandatory=$false)]
         [ValidateSet("normal", "category", "transactional")]
         [String]$Category = "normal"

    )

    process {

        # Checking the name
        If ( $Name -match '^[a-zA-Z0-9_]+$' ) {
            # ok
            Write-Verbose "The attribute name '$( $Name )' is valid."
        } else {
            Throw "The attribute name '$( $Name )' is not valid. Only alphanumeric characters and underscores are allowed."
        }

        # Create params
        $params = @{
            "Object" = "contacts/attributes"
            "Path" = "$( $Category )/$( $Name.ToUpper() )"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                "type"     = $Type
            }
        }

        # add verbose flag, if set
        if ($PSBoundParameters["Verbose"].IsPresent -eq $true) {
            $params.Add("Verbose", $true)
        }

        # Request attribute creation
        $attribute = Invoke-Brevo @params

        # return
        $attribute
    }
}