
# TODO implement paging
# TODO implement the all switch
# TODO implement the include and exclude parameter with default values


function Get-Payment {
    [CmdletBinding(DefaultParameterSetName = 'Collection')]
    param (

        [Parameter(Mandatory=$true, ParameterSetName = 'Single')][String]$Uuid

        ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')]
         [Long]$FromUnixtime = 0
        
        #,[Parameter(Mandatory=$false)][String]$FromDate = ""                        # string like 2024-06-16
        
         ,[Parameter(Mandatory=$false, ParameterSetName = 'Collection')][Switch]$All = $false

         ,[Parameter(Mandatory=$false)]
         #[ValidateSet("adhoc", "recurring", "newsletter", "onevent", "testmail", "multilanguage", "broadcast", IgnoreCase = $false)]
         [Array]$Include = [Array]@()             # adhoc|recurring|newsletter|onevent|testmail|multilanguage|broadcast - multiple values are allowed

         ,[Parameter(Mandatory=$false)]
         #[ValidateSet("adhoc", "recurring", "newsletter", "onevent", "testmail", "multilanguage", "broadcast", IgnoreCase = $false)]
         [Array]$Exclude = [Array]@("charged_by")             # adhoc|recurring|newsletter|onevent|testmail|multilanguage|broadcast - multiple values are allowed

        
    )

    begin {

    }

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # Create params
                $params = [Hashtable]@{
                    "Object" = "payments"
                    "Method" = "GET"
                    "Path" = $Uuid
                }

                break
            }

            'Collection' {

                <#
                If ( $FromDate -ne "" ) {
                    $f = [Datetime]::Today
                    If ( [Datetime]::TryParse($FromDate,[ref]$f) -eq $true ) {
                        $query | Add-Member -MemberType NoteProperty -Name "fromdate" -Value $f.ToString("yyyy-MM-dd")
                    } else {
                        throw "FromDate is not valid"
                    }
                } else {
                    # Set nothing
                }
                #>

                # Just list donations
                $search = [PSCustomObject]@{
                    "query" = [PSCustomObject]@{
                        '$range' = [PSCustomObject]@{
                            "created" = [PSCustomObject]@{
                                #"lt" = "2024-04-23",
                                "gt" = $FromUnixtime #"2024-01-01",
                                #"format" = "yyyy-MM-dd"
                            }
                        }
                    }
                    "sort" = [Array]@(
                        [PSCustomObject]@{
                            "field" = "created"
                            "field_type" = "numeric" # string|numeric|boolean
                            "direction" = "asc" # asc|desc
                        }
                    )
                    "size" = 100        # max 10k records and 10MB
                    "from" = 0 # TODO needed to add paging
                    "includes" = $Include #[Array]@()
                    "excludes" = $Exclude #[Array]@("charged_by")
                }

                # Create params
                $params = [Hashtable]@{
                    "Object" = "search/payments"
                    "Method" = "POST"
                    "Body" = $search
                }


                # Add paging
                <#
                If ( $All -eq $true ) {
                    $params.Add("Paging", $true)
                    $params.Add("PageSize", 1000)
                }
                #>
                
                break
            }
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}

        # Request list(s)
        $payment = Invoke-RaiseNow @params

        # Return
        switch ($PSCmdlet.ParameterSetName) {
            'Single' {

                # return
                $payment

                break
            }

            'Collection' {

                # Logging
                Write-Verbose "Got $( $payment.summary.hits ) payments"
                Write-Verbose "Last sort value $( $payments.summary.last_sort_values )" # this has three zeros at the end for milliseconds
                                                                                        # which would need to be removed when caching that

                # return
                #If ( $All -eq $true ) {
                    $payment.hits
                #} else {
                #    $contacts.contacts
                #}
                
                break
            }
        }

    }

    end {

    }

}
