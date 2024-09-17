


function Invoke-RaiseNow {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Object                                # The Brevo object like groups or contacts (first part after the main url)
        ,[Parameter(Mandatory=$false)][String]$Path = ""                            # The path in the url after the object
        ,[Parameter(Mandatory=$false)][PSCustomObject]$Query = [PSCustomObject]@{}  # Query parameters for the url
        ,[Parameter(Mandatory=$false)][Switch]$Paging = $false                      # Automatic paging through the result, only needed for a few calls
        ,[Parameter(Mandatory=$false)][Int]$Pagesize = 0                          # Pagesize, if not defined in settings. For reports the max is 100.
        ,[Parameter(Mandatory=$false)][ValidateScript({
            If ($_ -is [PSCustomObject]) {
                [PSCustomObject]$_
            } ElseIf ($_ -is [System.Collections.ArrayList] -or $_ -is [Array]) {
                [System.Collections.ArrayList]$_
            }
        })]$Body = [PSCustomObject]@{}   # Body to upload, e.g. for POST and PUT requests, will automatically transformed into JSON
    )
    DynamicParam {
        # All parameters, except Uri and body (needed as an object)
        $p = Get-BaseParameters "Invoke-WebRequest"
        [void]$p.remove("Uri")
        [void]$p.remove("Body")
        $p
    }

    Begin {


        #-----------------------------------------------
        # CREATE URL
        #-----------------------------------------------

        If ( $Script:settings.base.endswith("/") -eq $true ) {
            $base = $Script:settings.base
        } else {
            $base = "$( $Script:settings.base )/"
        }


        #-----------------------------------------------
        # CHECK INPUT PARAMETERS
        #-----------------------------------------------

        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        If ( $Script:debugMode -eq $true ) {
            Write-Host "INPUT: $( Convertto-json -InputObject $PSBoundParameters -Depth 99 -Compress )"
        }


        #-----------------------------------------------
        # AUTHENTICATION
        #-----------------------------------------------
        
        # Only read it, when no variable in cache yet
        $token = ""
        If ( $Script:variableCache.Keys -contains "access_token" ) {
            # Good, there is a token
            $token = $Script:variableCache."access_token"
        } else {
            # Read the token from a file and check it OR create a new one
            $token = Save-NewToken
        }

        $header = [Hashtable]@{
            "Authorization" = "Bearer $( $token )"
            #"Accept" = "application/json"
        }

        # Empty the token variables
        $token = ""

        
        #-----------------------------------------------
        # HEADERS
        #-----------------------------------------------

        # Add auth header or just set it
        If ( $updatedParameters.ContainsKey("Headers") -eq $true ) {
            $header.Keys | ForEach-Object {
                $key = $_
                $updatedParameters.Headers.Add( $key, $header.$key )
            }
        } else {
            $updatedParameters.add("Headers",$header)
        }

        # Add additional headers from the settings, e.g. for api gateways or proxies
        $Script:settings.additionalHeaders.PSObject.Properties | ForEach-Object {
            $updatedParameters.Headers.add($_.Name, $_.Value)
        }

        #-----------------------------------------------
        # CONTENT TYPE
        #-----------------------------------------------

        # Set content type, if not present yet
        If ( $updatedParameters.ContainsKey("ContentType") -eq $false) {
            $updatedParameters.add("ContentType",$ContentType)
        }


        #-----------------------------------------------
        # PATH
        #-----------------------------------------------

        # normalize the path, remove leading and trailing slashes
        If ( $Path -ne "") {
            If ( $Path.StartsWith("/") -eq $true ) {
                #$Path = $Path.Substring(1)
            } else {
                $Path = "/$( $Path )"
            }
            If ( $Path.EndsWith("/") -eq $true ) {
                $Path = $Path -replace ".$"
            }
        }


        #-----------------------------------------------
        # PAGING
        #-----------------------------------------------

        # set the pagesize
        <#
        If ( $Pagesize -gt 0 ) {
            $currentPagesize = $Pagesize
        } else {
            $currentPagesize = $Script:settings.pageSize
        }
        #>

        # set paging parameters
        <#
        If ( $Paging -eq $true ) {

            Switch ( $updatedParameters.Method ) {

                "GET"{
                    #Write-Host "get"
                    $Query | Add-Member -MemberType NoteProperty -Name "pagesize" -Value $currentPagesize  #$Script:settings.pageSize
                    $Query | Add-Member -MemberType NoteProperty -Name "page" -Value 0
                }

                "POST" {
                    If ( $Body -is [PSCustomObject] ) {
                        $Body | Add-Member -MemberType NoteProperty -Name "pagesize" -Value $currentPagesize # $Script:settings.pageSize
                        $Body | Add-Member -MemberType NoteProperty -Name "page" -Value 0
                    # } elseif ( $Body -is [System.Collections.Specialized.OrderedDictionary] ) {
                    #     $Body.add("pagesize", $Script:settings.pageSize)
                    #     $Body.add("page", 0)
                    }
                }

            }

            # Add a collection instead of a single object for the return
            $res = [System.Collections.ArrayList]@()

        }
        #>

    }

    Process {

        #-----------------------------------------------
        # PREPARE BODY
        #-----------------------------------------------

        If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
            $bodyJson = ConvertTo-Json -InputObject $Body -Depth 99 -Compress
            $updatedParameters.Body = $bodyJson
        }

        $finished = $false
        $continueAfterTokenRefresh = $false
        Do {

            # Execute the request
            try {

                #-----------------------------------------------
                # PREPARE QUERY
                #-----------------------------------------------

                $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
                $Query.PSObject.Properties | ForEach-Object {
                    $nvCollection.Add( $_.Name, $_.Value )
                }

                #-----------------------------------------------
                # PREPARE URL
                #-----------------------------------------------

                $uriRequest = [System.UriBuilder]::new("$( $base )$( $object )$( $Path )")
                $uriRequest.Query = $nvCollection.ToString()
                $updatedParameters.Uri = $uriRequest.Uri.OriginalString

                # Output parameters in debug mode
                If ( $Script:debugMode -eq $true -or $PSBoundParameters["Verbose"].IsPresent -eq $true) {
                    Write-Host "REST: $( Convertto-json -InputObject $updatedParameters -Depth 99 )"
                }

                If ( $Script:logAPIrequests -eq $true ) {
                    Write-Log -Message "$( $updatedParameters.Method.ToString().ToUpper() ) $( $updatedParameters.Uri )" -severity verbose
                }

                $wrInput = [Hashtable]@{
                    "Params" = $updatedParameters
                    "RetryHttpErrorList" = $Script:settings.errorhandling.RepeatOnHttpErrors
                    "MaxTriesSpecific" = $Script:settings.errorhandling.MaximumRetriesOnHttpErrorList
                    "MaxTriesGeneric" = $Script:settings.errorhandling.MaximumRetriesGeneric
                    "MillisecondsDelay" = $Script:settings.errorhandling.HttpErrorDelay
                    "ForceUTF8Return" = $false
                }
                $req = @( Invoke-WebRequestWithErrorHandling @wrInput )
                
                $wr =  convertfrom-json -InputObject $req.content

            } catch {

                $e = $_

                Write-Log -Message $e.Exception.Message -Severity ERROR

                # parse the response code and body
                $errResponse = $e.Exception.Response
                $errBody = Import-ErrorForResponseBody -Err $e

                # Do this only once
                if ( $errResponse.StatusCode.value__ -eq 401 -and $continueAfterTokenRefresh -eq $false) {

                    Write-Log -Severity WARNING -Message "401 Unauthorized"
                    try {
                        $newToken = Save-NewToken
                        Write-Log -Severity WARNING -Message "Successful token refresh"
                        $wrInput.Params.Headers.Authorization = "Bearer $( $newToken )"
                        $continueAfterTokenRefresh = $true
                    } catch {
                        Write-Log -Severity ERROR -Message "Token refresh not successful"
                    }

                    If ( $continueAfterTokenRefresh -eq $true ) {
                        Continue
                    }

                }

                throw $_

            }

            # Increase page and add results to the collection
            If ( $Paging -eq $true ) {

                Write-Verbose "Jumping into next page"
                #$Script:pluginDebug = $wr

                # When using paging, we want the first subobject
                $wrItems = $wr.psobject.properties.where({ $_.MemberType -eq "NoteProperty" })[0].Value

                # If the result equals the pagesize, try it one more time with the next page
                If ( $wrItems.Count -eq $currentPagesize ) {

                    Write-Verbose "Set next batch"

                    Switch ( $updatedParameters.Method ) {

                        "GET"{
                            $Query.offset += $currentPagesize
                        }
                        <#
                        "POST" {
                            $Body.offset += currentPagesize
                        }
                        #>
                    }

                } else {

                    # If this is less than the page size -> done!
                    $finished = $true

                }

                # Add result to return collection
                [void]$res.Add($wrItems)

            } else {

                # If this is only one request without paging -> done!
                $finished = $true

            }

            #-----------------------------------------------
            # SAVE CURRENT RATE
            #-----------------------------------------------
            
            # documentation: https://developers.brevo.com/docs/api-limits
<#
            $Script:pluginDebug = $req

            # Prevent problems as some calls do not have rate limiting
            If ( $null -ne $req.Headers."x-sib-ratelimit-limit" ) {
                $apiRateLimit = [UInt64]( $req.Headers."x-sib-ratelimit-limit".trim() )
                $apiRateRemaining = [UInt64]( $req.Headers."x-sib-ratelimit-remaining".trim() )
                $apiRateReset = ( Get-Unixtime ) + [UInt64]( $req.Headers."x-sib-ratelimit-reset".trim() )
                If ( $Script:variableCache.Keys -contains "api_rate_remaining" ) {
                    $Script:variableCache."api_rate_limit" = $apiRateLimit               # Request limit per minute
                    $Script:variableCache."api_rate_remaining" = $apiRateRemaining       # The number of requests left for the time window
                    $Script:variableCache."api_rate_reset" = $apiRateReset               # The time when the rate limit window resets as a unix timestamp
                } else {
                    #$apiRateReset = ( Get-Unixtime ) + 60 # at the first call this is just 60 seconds by default
                    $Script:variableCache.Add("api_rate_limit", $apiRateLimit )          # Request limit per minute
                    $Script:variableCache.Add("api_rate_remaining", $apiRateRemaining )  # The number of requests left for the time window
                    $Script:variableCache.Add("api_rate_reset", $apiRateReset )          # The time when the rate limit window resets as a unix timestamp
                }
            }
          #>  

        } Until ( $finished -eq $true )

    }

    End {

        If ( $Paging -eq $true ) {
            $res
        } else {
            $wr
        }

    }

 }

