
function Get-Mailing {
    [CmdletBinding()]
    param (

        # Query parameters
        [Parameter(Mandatory=$false)]
        [ValidateSet("REGULAR_MAILING", "ACTION_MAILING", "TIME_TRIGGER_MAILING", "SUBSCRIPTION_TRIGGER_MAILING", "SPLIT_TEST_MAILING", IgnoreCase = $false)]
        [Array]$Type = [Array]@()             # REGULAR_MAILING|ACTION_MAILING|TIME_TRIGGER_MAILING|SUBSCRIPTION_TRIGGER_MAILING|SPLIT_TEST_MAILING - multiple values are allowed
        ,[Parameter(Mandatory=$false)]
        [Array]$ListIds = [Array]@()             # REGULAR_MAILING|ACTION_MAILING|TIME_TRIGGER_MAILING|SUBSCRIPTION_TRIGGER_MAILING|SPLIT_TEST_MAILING - multiple values are allowed
        ,[Parameter(Mandatory=$false)][Switch]$IsApproved = $false      # Only approved mailings
        ,[Parameter(Mandatory=$false)][Switch]$ReadyToSend = $false     # Only mailings ready to send
        ,[Parameter(Mandatory=$false)][Switch]$HasSending = $false      # Only mailings with sends

        ,[Parameter(Mandatory=$false)][String]$CreatedAfter = ""        # string like 2024-06-16
        ,[Parameter(Mandatory=$false)][String]$CreatedBefore = ""       # string like 2024-06-16
        ,[Parameter(Mandatory=$false)][String]$ModifiedAfter = ""       # string like 2024-06-16
        ,[Parameter(Mandatory=$false)][String]$ModifiedBefore = ""      # string like 2024-06-16
        ,[Parameter(Mandatory=$false)][String]$SentAfter = ""           # string like 2024-06-16
        
        # Generic
        ,[Parameter(Mandatory=$false)][Switch]$All = $false             # Return all mailings through paging
        ,[Parameter(Mandatory=$false)][Switch]$IncludeLinks = $false    # Should the links also be included?

    )

    begin {


        #-----------------------------------------------
        # DEFINE QUERY
        #-----------------------------------------------

        <#
            [x] createdAfter
            [x] createdBefore
            [x] modifiedAfter
            [x] modifiedBefore
            [x] sentAfter
            [x] types
            [x] listIds
            [x] readyToSend
            [x] isApproved
            [x] hasSending
            [ ] embedded
        #>

        $query = [PSCustomObject]@{}

        # Set the approval status
        If ( $IsApproved -eq $true ) {
            $query | Add-Member -MemberType NoteProperty -Name "isApproved" -Value "true"
        }

        # Set the approval status
        If ( $ReadyToSend -eq $true ) {
            $query | Add-Member -MemberType NoteProperty -Name "readyToSend" -Value "true"
        }

        # Set the approval status
        If ( $HasSending -eq $true ) {
            $query | Add-Member -MemberType NoteProperty -Name "hasSending" -Value "true"
        }

        # Set the type filter
        If ( $Type.Count -gt 0 ) {
            $query | Add-Member -MemberType NoteProperty -Name "types" -Value ( $Type -join "," )
        }

        # Set the list filter
        If ( $ListIds.Count -gt 0 ) {
            $query | Add-Member -MemberType NoteProperty -Name "listIds" -Value ( $ListIds -join "," )
        }

        # Check the date
        If ( $CreatedAfter -ne "" ) {
            $f = [Datetime]::Today
            If ( [Datetime]::TryParse($CreatedAfter,[ref]$f) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "createdAfter" -Value $f.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture) # 2024-06-18T08:24:36Z
            } else {
                throw "CreatedAfter is not valid"
            }
        } else {
            # Set nothing
        }

        # Check the date
        If ( $CreatedBefore -ne "" ) {
            $f = [Datetime]::Today
            If ( [Datetime]::TryParse($CreatedBefore,[ref]$f) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "createdBefore" -Value $f.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture) # 2024-06-18T08:24:36Z
            } else {
                throw "CreatedBefore is not valid"
            }
        } else {
            # Set nothing
        }

        # Check the date
        If ( $ModifiedAfter -ne "" ) {
            $f = [Datetime]::Today
            If ( [Datetime]::TryParse($ModifiedAfter,[ref]$f) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "modifiedAfter" -Value $f.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture) # 2024-06-18T08:24:36Z
            } else {
                throw "ModifiedAfter is not valid"
            }
        } else {
            # Set nothing
        }

        # Check the date
        If ( $ModifiedBefore -ne "" ) {
            $f = [Datetime]::Today
            If ( [Datetime]::TryParse($ModifiedBefore,[ref]$f) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "modifiedBefore" -Value $f.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture) # 2024-06-18T08:24:36Z
            } else {
                throw "ModifiedBefore is not valid"
            }
        } else {
            # Set nothing
        }

        # Check the date
        If ( $SentAfter -ne "" ) {
            $f = [Datetime]::Today
            If ( [Datetime]::TryParse($SentAfter,[ref]$f) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "sentAfter" -Value $f.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture) # 2024-06-18T08:24:36Z
            } else {
                throw "SentAfter is not valid"
            }
        } else {
            # Set nothing
        }


        #-----------------------------------------------
        # CALL PARAMETERS
        #-----------------------------------------------

        # Create params
        $params = [Hashtable]@{
            "Object" = "mailings"
            "Method" = "GET"
            "Query" = $query
            "PageSize" = 100
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Add paging
        If ( $All -eq $true ) {
            $params.Add("Paging", $true)
        }


    }

    process {



        # Request mailings
        $mailings = Invoke-XPro @params

        # Exclude mailings
        # If ( $Type.Count -gt 0 ) {
        #     $mailingsToFilter = $mailings."_embedded"."inx:mailings" | Where-Object { $_.type -in $type }
        # } else {
        #     $mailingsToFilter = $mailings."_embedded"."inx:mailings"
        # }
        $mailingsToFilter = $mailings."_embedded"."inx:mailings"
        
        # return
        If ( $IncludeLinks -eq $true ) {
            $mailingsToFilter
        } else {
            $mailingsToFilter | Select-Object * -ExcludeProperty "_links"
        }


    }

    end {

    }

}


