<#
$fields = Invoke-RestMethod -Verbose -Uri "$( $settings.base )/v1/dataMappingFields" -Method Get -Headers $headers -ContentType $contentType #-Body $bodyJson -TimeoutSec $maxTimeout

# TODO [ ] decisions to make: fullName or firstName+lastName / address1 or street+houseNumber / companyName if no fullname or lastname -> automatically checked from optilyz at upload

# Add fields for matching that are missing in the previous API call
$moreFields = @()
$moreFields += "address1"
1..99 | ForEach {
    $moreFields += "individualisation$( $_ )"
}



label                 fieldName          required type      
-----                 ---------          -------- ----
Title                 jobTitle              False string
Salutation            title                 False string
First Name            firstName             False string
Last Name             lastName               True string
Company Name          companyName1          False string
Company Name 2        companyName2          False string
Company Name 3        companyName3          False string
Street                street                 True string    
House Number          houseNumber           False string
Other address details address2              False string
More address details  address3              False string
Zip Code              zipCode                True string
City                  city                   True string
Country               country               False string
Individualisation     individualisations    False collection
c/o (care of)         careOf                False string
Gender                gender                False string
Other titles          otherTitles           False string
#>


function Get-Field {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (
    )

    begin {
        
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'Collection' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "dataMappingFields"
                    "Method" = "GET"
                    "ApiVersion" = 1
                }
                
                break
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $fields = Invoke-Optilyz @params

        # Return
        switch ($PSCmdlet.ParameterSetName) {

            'Collection' {

                # return
                $fields

                break
            }
        }

    }

    end {

    }

}

