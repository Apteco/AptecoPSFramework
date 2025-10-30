function Remove-List {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [Int]$ListId

    )

    process {
        # Create params for DELETE request
        $params = @{
            "Object" = "contacts/lists/$( $ListId )"
            "Method" = "DELETE"
        }

        # add verbose flag, if set
        if ($PSBoundParameters["Verbose"].IsPresent -eq $true) {
            $params.Add("Verbose", $true)
        }

        # Request list deletion
        $result = Invoke-Brevo @params

        # return result
        $result
    }
}