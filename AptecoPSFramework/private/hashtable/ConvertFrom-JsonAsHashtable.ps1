Function ConvertFrom-JsonAsHashtable {

    # To solve these problems, load the content with Invoke-WebRequest rather than Invoke-RestMethod, and convert the content with the function above

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                Position = 0,
                ValueFromPipeline = $true)]
            [AllowEmptyString()]
            [String] $InputObject
    )
    DynamicParam {
        # All parameters, except Uri and body (needed as an object)
        $p = Get-BaseParameters "ConvertFrom-Json"
        [void]$p.remove("InputObject")
        $p
    }

    Begin {
        $jsSerializer = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
    }

    Process {

        Write-Verbose $InputObject
        $jsSerializer.Deserialize($InputObject, 'Hashtable')

    }

    end {
        $jsSerializer = $null
    }

}