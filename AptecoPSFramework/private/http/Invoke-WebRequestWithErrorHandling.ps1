﻿# $params =[Hashtable]@{
#     "Uri" = "https://requestly.dev/api/mockv2/helloworld?rq_uid=UyRFxSA8PHPgJg6VKNz2tQZYlI23"
# }

# TODO maybe put all http functions into one module

<#
$wr = @( Invoke-RestMethodWithErrorHandling -Params $params )
#>

function Invoke-WebRequestWithErrorHandling {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][Hashtable]$Params
        ,[Parameter(Mandatory=$false)][Array]$RetryHttpErrorList = [Array]@(502)    # http errors that should used for $maxTriesSpecific
        ,[Parameter(Mandatory=$false)][int]$MaxTriesSpecific = 3                    # Specific http errors that are catched, see $RetryHttpErrorList
        ,[Parameter(Mandatory=$false)][int]$MaxTriesGeneric = 1                     # Generic errors that are not specifically catched
        ,[Parameter(Mandatory=$false)][int]$MillisecondsDelay = 200                 # Delay for the case of an exception
        ,[Parameter(Mandatory=$false)][Switch]$ForceUTF8Return = $false             # Sometimes the returned result is not correctly encoded, this switch fixes it
    )

    begin {

        # Clear the error object
        $Error.Clear()
        $completed = $false

    }

    process {

        $response = $null
        $specificCounter = 0
        $genericCounter = 0
        do {

            try {

                If ( $ForceUTF8Return -eq $true ) {
                    $response = Invoke-WebRequestUTF8 @Params -ErrorAction Stop -UseBasicParsing
                } else {
                    $response = Invoke-WebRequest @Params -ErrorAction Stop -UseBasicParsing
                }
                $completed = $true

            } catch {

                $e = $_

                # parse the response code and body
                $errResponse = $e.Exception.Response
                $errBody = Import-ErrorForResponseBody -Err $e

                #$errResponse.StatusCode.value__ #= 502
                #$errResponse.StatusCode.ToString() # = "BadGateway"
                #$errResponse.ReasonPhrase # = "Bad Gateway"

                # directly throw an exception so we can catch it in the caller
                if ( $errResponse.StatusCode.value__ -eq 401 ) {
                    throw $e #.exception
                }

                # retry if a specific http error happens
                if ( $RetryHttpErrorList -contains $errResponse.StatusCode.value__ ) {

                    $specificCounter += 1

                    # Exceeded all retries
                    if ($specificCounter -ge $MaxTriesSpecific) {

                        If ( $null -eq $errResponse.StatusCode.value__ ) {
                            $errString = "Unknown error"
                        } else {
                            $errString = "$( $errResponse.StatusCode.value__ ) $( $errResponse.StatusCode.ToString() )"
                        }

                        Write-Log -Message "Request attempt $( $specificCounter ) failed with '$( $errString )'. Command failed the maximum number of $( $MaxTriesSpecific ) times."  -Severity WARNING
                        #Write-Log -Message $_.Exception.Message -Severity ERROR
                        Write-Log -Message "RESPONSE: $( ConvertTo-Json -InputObject $errBody -Depth 99 -Compress)" -Severity WARNING
                        throw $e #.Exception

                    # Not all specific tries used yet, repeat
                    } else {
                        Write-Log -Message "Request $( $specificCounter ) failed with $( $errResponse.StatusCode.value__ ) $( $errResponse.StatusCode.ToString() ). Retrying in $( $MillisecondsDelay ) milliseconds."
                        Start-Sleep -Milliseconds $MillisecondsDelay
                        Continue
                    }

                # generic problems
                } else {

                    $genericCounter += 1

                    # Exceeded all retries
                    if ($genericCounter -ge $MaxTriesGeneric) {
                        Write-Log -Message "Request $( $genericCounter ) failed. Command failed the maximum number of $( $MaxTriesGeneric ) times." -Severity WARNING
                        #Write-Log -Message $_.Exception.Message -Severity ERROR
                        Write-Log -Message "RESPONSE: $( ConvertTo-Json -InputObject $errBody -Depth 99 -Compress)"
                        throw $e #.Exception

                    # Not all generic tries used yet, repeat
                    } else {
                        Write-Log -Message "Request $( $genericCounter ) failed. Retrying in $( $MillisecondsDelay ) milliseconds." -Severity WARNING
                        Start-Sleep -Milliseconds $MillisecondsDelay
                        Continue
                    }

                }

            }

        } until ( $completed -eq $true -or $specificCounter -ge $MaxTriesSpecific -or $genericCounter -ge $MaxTriesGeneric)

    }

    end {

        # Clear the error object
        $Error.Clear()

        # Return: Make sure it is not really null to imitate Invoke-RestMethod
        # Give the whole object back so we can read headers and more information
        $response

    }

}