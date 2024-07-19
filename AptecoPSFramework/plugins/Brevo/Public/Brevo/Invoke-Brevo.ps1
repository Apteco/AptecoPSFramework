

function Invoke-Brevo {

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
            # } elseif ($_ -is [System.Collections.Specialized.OrderedDictionary]) {
            #     [System.Collections.Specialized.OrderedDictionary]$_
            # }
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

        # check type of body, if present
        <#
        If ($Body -is [PSCustomObject]) {
            Write-Host "PSCustomObject"
        } ElseIf ($Body -is [System.Collections.ArrayList]) {
            Write-Host "ArrayList"
        } else {
            Throw 'Body datatype not valid'
        }
        #>

        # check url, if it ends with a slash
        If ( $Script:settings.base.endswith("/") -eq $true ) {
            $base = $Script:settings.base
        } else {
            $base = "$( $Script:settings.base )/"
        }

        # Reduce input parameters to only allowed ones
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        # Output parameters in debug mode
        If ( $Script:debugMode -eq $true ) {
            Write-Host "INPUT: $( Convertto-json -InputObject $PSBoundParameters -Depth 99 -Compress )"
        }

        # Build up header
        $header = [Hashtable]@{
            "api-key" = "$( ( Convert-SecureToPlaintext -String $Script:settings.login.apikey ) )"
        }

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

        # Set content type, if not present yet
        If ( $updatedParameters.ContainsKey("ContentType") -eq $false) {
            $updatedParameters.add("ContentType",$Script:settings.contentType)
        }

        # normalize the path, remove leading and trailing slashes
        If ( $Path -ne "") {
            If ( $Path.StartsWith("/") -eq $true ) {
                $Path = $Path.Substring(1)
            }
            If ( $Path.EndsWith("/") -eq $true ) {
                $Path = $Path -replace ".$"
            }
        }

        # set the pagesize
        If ( $Pagesize -gt 0 ) {
            $currentPagesize = $Pagesize
        } else {
            $currentPagesize = $Script:settings.pageSize
        }

        # set paging parameters
        If ( $Paging -eq $true -or $Pagesize -gt 0) {

            Switch ( $updatedParameters.Method ) {

                "GET"{
                    #Write-Host "get"
                    $Query | Add-Member -MemberType NoteProperty -Name "limit" -Value $currentPagesize  #$Script:settings.pageSize
                    $Query | Add-Member -MemberType NoteProperty -Name "offset" -Value 0
                }
<#
                "POST" {
                    If ( $Body -is [PSCustomObject] ) {
                        $Body | Add-Member -MemberType NoteProperty -Name "limit" -Value $currentPagesize # $Script:settings.pageSize
                        $Body | Add-Member -MemberType NoteProperty -Name "offset" -Value 0
                    # } elseif ( $Body -is [System.Collections.Specialized.OrderedDictionary] ) {
                    #     $Body.add("pagesize", $Script:settings.pageSize)
                    #     $Body.add("page", 0)
                    }
                }
#>
            }

            # Add a collection instead of a single object for the return
            $res = [System.Collections.ArrayList]@()

        }

    }

    Process {

        # Prepare Body
        If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
            $bodyJson = ConvertTo-Json -InputObject $Body -Depth 99 -Compress
            $updatedParameters.Body = $bodyJson
        }

        $finished = $false
        Do {

            # Execute the request
            try {

                # Prepare query
                $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
                $Query.PSObject.Properties | ForEach-Object {
                    $nvCollection.Add( $_.Name, $_.Value )
                }

                # Prepare URL
                $uriRequest = [System.UriBuilder]::new("$( $base )$( $object )/$( $Path )")
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