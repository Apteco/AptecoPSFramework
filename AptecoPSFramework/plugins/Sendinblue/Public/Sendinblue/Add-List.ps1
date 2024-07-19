
function Add-List {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Name
        ,[Parameter(Mandatory=$false)][Switch]$UsesEconda = $false
        ,[Parameter(Mandatory=$false)][Switch]$UsesGoogleAnalytics = $false
        ,[Parameter(Mandatory=$false)][Switch]$HasOpenTracking = $false
        ,[Parameter(Mandatory=$false)][Switch]$HasClickTracking = $false
        ,[Parameter(Mandatory=$false)][Switch]$HasConversionTracking = $false
        ,[Parameter(Mandatory=$false)][String]$Imprint = ""
        ,[Parameter(Mandatory=$false)][String]$HeaderFromEmail = ""
        ,[Parameter(Mandatory=$false)][String]$HeaderFromName = ""
        ,[Parameter(Mandatory=$false)][String]$HeaderReplyEmail = ""
        ,[Parameter(Mandatory=$false)][String]$HeaderReplyName = ""
        ,[Parameter(Mandatory=$false)][String]$TrackingUrl = ""
        ,[Parameter(Mandatory=$false)][String]$Landingpage = ""
        ,[Parameter(Mandatory=$false)][Switch]$UseEcgList = $false


    )

    begin {

    }

    process {

        # Create params
        $params = [Hashtable]@{
            "Object" = "lists"
            "Method" = "POST"
            "Body" = [PSCustomObject]@{
                    "name" = $Name
            }
        }

        If ( $UsesEconda -eq $true ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "uses_econda" -Value $true
        } else {
            $params.Body | Add-Member -MemberType NoteProperty -Name "uses_econda" -Value $false
        }

        If ( $UsesGoogleAnalytics -eq $true ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "uses_googleanalytics" -Value $true
        } else {
            $params.Body | Add-Member -MemberType NoteProperty -Name "uses_googleanalytics" -Value $false
        }

        If ( $HasOpenTracking -eq $true ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "has_opentracking" -Value $true
        } else {
            $params.Body | Add-Member -MemberType NoteProperty -Name "has_opentracking" -Value $false
        }

        If ( $HasClickTracking -eq $true ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "has_clicktracking" -Value $true
        } else {
            $params.Body | Add-Member -MemberType NoteProperty -Name "has_clicktracking" -Value $false
        }

        If ( $HasConversionTracking -eq $true ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "has_conversiontracking" -Value $true
        } else {
            $params.Body | Add-Member -MemberType NoteProperty -Name "has_conversiontracking" -Value $false
        }

        If ( $UseEcgList -eq $true ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "use_ecg_list" -Value $true
        } else {
            $params.Body | Add-Member -MemberType NoteProperty -Name "use_ecg_list" -Value $false
        }

        If ( $Imprint -ne "" ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "imprint" -Value $Imprint
        }

        If ( $TrackingUrl -ne "" ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "tracking_url" -Value $TrackingUrl
        } else {
            $params.Body | Add-Member -MemberType NoteProperty -Name "tracking_url" -Value $null
        }

        If ( $HeaderFromEmail -ne "" ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "header_from_email" -Value $HeaderFromEmail
        }

        If ( $HeaderFromName -ne "" ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "header_from_name" -Value $HeaderFromName
        }

        If ( $HeaderReplyEmail -ne "" ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "header_reply_email" -Value $HeaderReplyEmail
        }

        If ( $HeaderReplyName -ne "" ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "header_reply_name" -Value $HeaderReplyName
        }

        If ( $Landingpage -ne "" ) {
            $params.Body | Add-Member -MemberType NoteProperty -Name "landingpage" -Value $Landingpage
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request lists
        $list = Invoke-Sendinblue @params

        # return
        #If ( $IncludeLinks -eq $true ) {
            $list.value
        #} else {
        #    $list | Select-Object * -ExcludeProperty "_links"
        #}

    }

    end {

    }

}

