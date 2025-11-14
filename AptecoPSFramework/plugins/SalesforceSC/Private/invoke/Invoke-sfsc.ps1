


function Invoke-SFSC {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Object                                # The cleverreach object like groups or mailings (first part after the main url)
        ,[Parameter(Mandatory=$false)][String]$Service = "data"
        ,[Parameter(Mandatory=$false)][String]$ContentType = "application/json"
        ,[Parameter(Mandatory=$false)][String]$Path = ""                            # The path in the url after the object
        ,[Parameter(Mandatory=$false)][PSCustomObject]$Query = [PSCustomObject]@{}  # Query parameters for the url
        #,[Parameter(Mandatory=$false)][Switch]$Paging = $false                      # Automatic paging through the result, only needed for a few calls
        #,[Parameter(Mandatory=$false)][Int]$Pagesize = 0                          # Pagesize, if not defined in settings. For reports the max is 100.
        ,[Parameter(Mandatory=$false)][ValidateScript({
             If ($_ -is [PSCustomObject]) {
                 [PSCustomObject]$_
              # } elseif ($_ -is [System.Collections.Specialized.OrderedDictionary]) {
              #     [System.Collections.Specialized.OrderedDictionary]$_
              # }
        #      } ElseIf ($_ -is [System.Collections.ArrayList] -or $_ -is [Array]) {
        #         [System.Collections.ArrayList]$_
             }
         })]$Body = [PSCustomObject]@{}   # Body to upload, e.g. for POST and PUT requests, will automatically transformed into JSON
    )
    DynamicParam {
        # All parameters, except Uri and body (needed as an object)
        $p = Get-BaseParameters "Invoke-WebRequest"
        [void]$p.remove("Uri")
        [void]$p.remove("Body")
        [void]$p.remove("ContentType")
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


        # Build custom salesforce domain
        $base = "https://$( $Script:settings.login.mydomain ).$( $base )services/$( $Service )/v$( $script:settings.apiversion )/"

        # Reduce input parameters to only allowed ones
        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        # Output parameters in debug mode
        If ( $Script:debugMode -eq $true -or $PSBoundParameters["Verbose"].IsPresent -eq $true) {
            Write-Host "INPUT: $( Convertto-json -InputObject $PSBoundParameters -Depth 99 )"
        }


        #-----------------------------------------------
        # AUTHENTICATION
        #-----------------------------------------------

        If ( $Script:settings.token.tokenUsage -eq "consume" ) {
            #$rawToken = Get-Content -Path $Script:settings.token.tokenFilePath -Encoding UTF8 -Raw
            $rawToken = ( Get-Content -Path $Script:settings.token.tokenFilePath -Encoding UTF8 -Raw ).replace("`n","").replace("`r","")
            If ( $Script:settings.token.encryptTokenFile -eq $true ) {
                $token = Convert-SecureToPlaintext -String $rawToken
            } else {
                $token = $rawToken
            }
        } elseif ( $Script:settings.token.tokenUsage -eq "generate" ) {
            If ( $Script:settings.encryptCredentials -eq $true ) {
                # Decrypt credentials
                $token = Convert-SecureToPlaintext -String $Script:settings.login.accesstoken
            } else {
                # Just use plaintext
                $token = $Script:settings.login.accesstoken
            }
        } else {
            throw "No token available!"
            exit 0
        }

        # Build up header
        $header = [Hashtable]@{
            "Authorization" = "Bearer $( $token )"
            "Accept" = "application/json"
            "X-PrettyPrint" = 1
        }

        # Empty the token variables
        $token = ""
        $rawToken = ""


        #-----------------------------------------------
        # HEADER
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


        #-----------------------------------------------
        # ADDITIONAL HEADERS
        #-----------------------------------------------

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
                $Path = $Path.Substring(1)
            }
            If ( $Path.EndsWith("/") -eq $true ) {
                $Path = $Path -replace ".$"
            }
        }



        # Add a collection instead of a single object for the return
        $res = [System.Collections.ArrayList]@()

    }

    Process {

        $finished = $false
        $continueAfterTokenRefresh = $false
        Do {

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

            $uriRequest = [System.UriBuilder]::new("$( $base )$( $object )/$( $Path )")
            $uriRequest.Query = $nvCollection.ToString()
            $updatedParameters.Uri = $uriRequest.Uri.OriginalString

            # Prepare Body
            If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
                $bodyJson = ConvertTo-Json -InputObject $Body -Depth 99 -Compress
                $updatedParameters.Body = $bodyJson
            }

            # Execute the request
            try {

                # Output parameters in debug mode
                If ( $Script:debugMode -eq $true -or $PSBoundParameters["Verbose"].IsPresent -eq $true) {
                    Write-Host "REST: $( Convertto-json -InputObject $updatedParameters -Depth 99 )"
                }

                If ( $Script:logAPIrequests -eq $true ) {
                    Write-Log -Message "$( $updatedParameters.Method.ToString().ToUpper() ) $( $updatedParameters.Uri )" -severity verbose
                }

                #Write-Host ( convertto-json $updatedParameters )
                $wrInput = [Hashtable]@{
                    "Params" = $updatedParameters
                    "RetryHttpErrorList" = $Script:settings.errorhandling.RepeatOnHttpErrors
                    "MaxTriesSpecific" = $Script:settings.errorhandling.MaximumRetriesOnHttpErrorList
                    "MaxTriesGeneric" = $Script:settings.errorhandling.MaximumRetriesGeneric
                    "MillisecondsDelay" = $Script:settings.errorhandling.HttpErrorDelay
                    "ForceUTF8Return" = $True
                }
                $wr = @( Invoke-WebRequestWithErrorHandling @wrInput )
                #$wr = Invoke-WebRequest @updatedParameters -UseBasicParsing

            } catch {

                $e = $_


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

                } else {

                # $responseStream = $_.Exception.Response.GetResponseStream()
                # $responseReader = [System.IO.StreamReader]::new($responseStream)
                # $responseBody = $responseReader.ReadToEnd()
                # Write-Log -Message $responseBody -Severity ERROR

                    Write-Log -Message $e.Exception.Message -Severity ERROR
                    throw $_.Exception

                }

            }

            # Increase page and add results to the collection
            If ( $wr.headers.Keys -contains "Sforce-Locator" ) {
                If ( $wr.headers."Sforce-Locator" -ne "null" ) {
                   If ( $Query.PsObject.properties.name -contains "locator" ) {
                        $Query."locator" = $wr.headers."Sforce-Locator"
                   } else {
                        $Query | Add-Member -MemberType NoteProperty -Name "locator" -Value $wr.headers."Sforce-Locator"
                   }
                } else {
                    $finished = $true
                }
            } else {
                $finished = $true
            }

            # Add result to return collection
            Switch -Wildcard ( $wr.headers.'Content-Type' ) {
                "text/csv*" {
                    [void]$res.AddRange(@( ConvertFrom-Csv -Delimiter "`t" -InputObject $wr.Content ))
                    break
                }

                "application/json*" {
                    [void]$res.AddRange(@( ConvertFrom-Json -InputObject $wr.content ))
                    break
                }

                default {
                    #$wr.Content
                }
            }

            If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
                Write-log $wr.Headers."Sforce-Limit-Info" -severity verbose #api-usage=2/15000
            }


            #-----------------------------------------------
            # SAVE CURRENT RATE AFTER LAST CALL
            #-----------------------------------------------

            If ( $Script:variableCache.Keys -contains "api_rate_limit" ) {
                $Script:variableCache.api_rate_limit = $wr.Headers."Sforce-Limit-Info".trim()
            } else {
                $Script:variableCache.Add("api_rate_limit",$wr.Headers."Sforce-Limit-Info".trim())
            }


        } Until ( $finished -eq $true )

        # If it was not added to the return collection and is not null, just return it blank
        If ( $res.Count -eq 0 -and $null -ne $wr.Content ) {
            $wr.Content

        # Otherwise return an empty array
        } elseif ( $res.Count -eq 0 -or $null -eq $wr.Content ) {
            [Array]@()

        # Or return the parsed response
        } else {
            $res
        }

    }

    End {

        <#
        If ( $Paging -eq $true ) {
            $res
        } else {
            $wr
        }
        #>

    }

 }

