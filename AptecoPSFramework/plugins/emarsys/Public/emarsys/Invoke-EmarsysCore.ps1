

function Invoke-EmarsysCore {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Object                                # The cleverreach object like groups or mailings (first part after the main url)
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

        #-----------------------------------------------
        # CHECK URL, IF IT ENDS WITH A SLASH
        #-----------------------------------------------

        If ( $Script:settings.base.endswith("/") -eq $true ) {
            $base = $Script:settings.base
        } else {
            $base = "$( $Script:settings.base )/"
        }


        #-----------------------------------------------
        # REDUCE INPUT PARAMETERS TO ONLY ALLOWED ONES
        #-----------------------------------------------

        $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters

        # Output parameters in debug mode
        If ( $Script:debugMode -eq $true ) {
            Write-Host "INPUT: $( Convertto-json -InputObject $PSBoundParameters -Depth 99 -Compress )"
        }


        #-----------------------------------------------
        # AUTH
        #-----------------------------------------------

        # Extract credentials
        $secret = Convert-SecureToPlaintext $Script:settings.login.secret
        $username = $Script:settings.login.username
        
        # Create nonce
        $randomStringAsHex = Get-RandomString -length 16 | Format-Hex
        $nonce = Get-StringfromByte -byteArray $randomStringAsHex.Bytes

        # Format date
        $date = [datetime]::UtcNow.ToString("o")

        # Create password digest
        $stringToSign = $nonce + $date + $secret
        $sha1 = Get-StringHash -inputString $stringToSign -hashName "SHA1"
        $passwordDigest = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sha1))

        # Combine Escher XWSSE header
        $xwsseArr = [System.Collections.ArrayList]@()
        [void]$xwsseArr.Add("UsernameToken Username=""$( $username )""")
        [void]$xwsseArr.Add("PasswordDigest=""$( $passwordDigest )""")
        [void]$xwsseArr.Add("Nonce=""$( $nonce )""")
        [void]$xwsseArr.Add("Created=""$( $date )""")
        $xwsse = $xwsseArr -join ", "

        # Empty the token variables
        $secret = ""


        #-----------------------------------------------
        # HEADERS
        #-----------------------------------------------

        # Build up header
        $header = [Hashtable]@{
            "X-WSSE"=$xwsse
            "X-Requested-With"=	"XMLHttpRequest"
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
        $Script:settings.additionalHeaders.PSObject.Properties | where-object { $_.MemberType -eq "NoteProperty" } | ForEach-Object {
            $updatedParameters.Headers.add($_.Name, $_.Value)
        }

        # Set content type, if not present yet
        If ( $updatedParameters.ContainsKey("ContentType") -eq $false) {
            $updatedParameters.add("ContentType",$Script:settings.contentType)
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


        #-----------------------------------------------
        # PAGING
        #-----------------------------------------------

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

        $finished = $false
        Do {

            # Prepare query
            $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            $Query.PSObject.Properties | ForEach-Object {
                $nvCollection.Add( $_.Name, $_.Value )
            }

            # Prepare URL
            $uriRequest = [System.UriBuilder]::new("$( $base )$( $object )/$( $Path )")
            $uriRequest.Query = $nvCollection.ToString()
            $updatedParameters.Uri = $uriRequest.Uri.OriginalString

            # Prepare Body
            If ( $updatedParameters.ContainsKey("Body") -eq $true ) {
                $bodyJson = ConvertTo-Json -InputObject $Body -Depth 99
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

                $wrInput = [Hashtable]@{
                    "Params" = $updatedParameters
                    "RetryHttpErrorList" = $Script:settings.errorhandling.RepeatOnHttpErrors
                    "MaxTriesSpecific" = $Script:settings.errorhandling.MaximumRetriesOnHttpErrorList
                    "MaxTriesGeneric" = $Script:settings.errorhandling.MaximumRetriesGeneric
                    "MillisecondsDelay" = $Script:settings.errorhandling.HttpErrorDelay
                    #"ForceUTF8Return" = $true
                }
                $req = @( Invoke-WebRequestWithErrorHandling @wrInput )
                #$Script:pluginDebug = $req
                $wr =  convertfrom-json -InputObject $req.content

            } catch {

                $e = $_

                Write-Log -Message $e.Exception.Message -Severity ERROR

                #$e | ConvertTo-Json | set-content "text.json" -Encoding UTF8


                # parse the response code and body
                #$errResponse = $e.Exception.Response
                $errBody = Import-ErrorForResponseBody -Err $e
                #$reqJson = convertfrom-json $errBody
               # $errBody | ConvertTo-Json | set-content "problem.json" -Encoding UTF8

                Write-Log -Message "emarsys error $( $errBody.replyCode ) - $( $errBody.replyText )" -Severity ERROR

                throw $_

            }

            # Increase page and add results to the collection
            If ( $Paging -eq $true ) {

                #Write-Verbose "Jumping into paging with $( $wr."Count" ) and $( $currentPagesize )"
                #$Script:pluginDebug = $wr

                # If the result equals the pagesize, try it one more time with the next page
                If ( $wr.Total -eq $currentPagesize ) {

                    Write-Verbose "Set pagesize"

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
                [void]$res.Add($wr)

            } else {

                # If this is only one request without paging -> done!
                $finished = $true

            }

        } Until ( $finished -eq $true )

    }

    End {

        If ( $Paging -eq $true ) {
            $res
        } else {
            If ( $wr.data ) {
                $wr.data
            } else {
                $wr
            }
            
        }

    }

}