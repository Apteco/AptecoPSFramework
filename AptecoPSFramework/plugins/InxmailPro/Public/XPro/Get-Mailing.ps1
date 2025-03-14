
function Get-Mailing {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

        # Query parameters

         [Parameter(Mandatory=$true, ParameterSetName = 'Single')][Int]$Id

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [ValidateSet("REGULAR_MAILING", "ACTION_MAILING", "TIME_TRIGGER_MAILING", "SUBSCRIPTION_TRIGGER_MAILING", "SPLIT_TEST_MAILING", IgnoreCase = $false)]
         [Array]$Type = [Array]@()             # REGULAR_MAILING|ACTION_MAILING|TIME_TRIGGER_MAILING|SUBSCRIPTION_TRIGGER_MAILING|SPLIT_TEST_MAILING - multiple values are allowed
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Array]$ListIds = [Array]@()             # REGULAR_MAILING|ACTION_MAILING|TIME_TRIGGER_MAILING|SUBSCRIPTION_TRIGGER_MAILING|SPLIT_TEST_MAILING - multiple values are allowed
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$IsApproved = $false      # Only approved mailings
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$ReadyToSend = $false     # Only mailings ready to send
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$HasSending = $false      # Only mailings with sends

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][String]$CreatedAfter = ""        # string like 2024-06-16
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][String]$CreatedBefore = ""       # string like 2024-06-16
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][String]$ModifiedAfter = ""       # string like 2024-06-16
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][String]$ModifiedBefore = ""      # string like 2024-06-16
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][String]$SentAfter = ""           # string like 2024-06-16
        
        # Generic
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false             # Return all mailings through paging
        
        ,[Parameter(Mandatory=$false, ParameterSetName = 'Single')]
         [Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Switch]$IncludeLinks = $false  # Should the links also be included?

    )

    begin {

        switch ($PSCmdlet.ParameterSetName) {
            
            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "mailings"
                    "Method" = "GET"
                    "Path" = $Id
                }

                break
            }

            'Collection' {

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

                # Add paging
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                }
                
                break
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
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

        # Return
        switch ($PSCmdlet.ParameterSetName) {

            'Single' {

                # return
                If ( $IncludeLinks -eq $true ) {
                    $mailings
                } else {
                    $mailings | Select-Object * -ExcludeProperty "_links"
                }

                break
            }

            'Collection' {

                $mailingsToFilter = $mailings."_embedded"."inx:mailings"
        
                # return
                If ( $IncludeLinks -eq $true ) {
                    $mailingsToFilter
                } else {
                    $mailingsToFilter | Select-Object * -ExcludeProperty "_links"
                }
                
                break
            }
        }


    }

    end {

    }

}


