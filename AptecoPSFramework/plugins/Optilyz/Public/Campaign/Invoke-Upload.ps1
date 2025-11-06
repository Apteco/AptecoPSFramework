
<#

$batchsize = $settings.upload.rowsPerUpload # Is 1000 in optilyz documentation
$maxTimeout = $settings.upload.timeout # normally the results should be sent back in less than 15 seconds



#-----------------------------------------------
# LOAD FIELDS
#-----------------------------------------------
Get-Field

Write-Log -message "Loaded attributes $( $fields.fieldName -join ", " )"




$urnFieldName = $params.UrnFieldName
$commkeyFieldName = $params.CommunicationKeyFieldName
$recipients = [System.Collections.ArrayList]@()
$dataCsv | ForEach {

    $addr = $_

    $address = [PSCustomObject]@{}
    $requiredFields | ForEach {
        $address | Add-Member -MemberType NoteProperty -Name $_ -Value $addr.$_
    }
    $colsEqual.InputObject | ForEach {
        $address | Add-Member -MemberType NoteProperty -Name $_ -Value $addr.$_
    }

    $recipient = [PSCustomObject]@{
        "urn" = $addr.$urnFieldName
        "communicationkey" = $addr.$commkeyFieldName #[guid]::NewGuid()
        "address" = $address
        "variation" = $addr.variation #$variations | Get-Random 
        "vouchers" = @() # array of @{"code"="XCODE123";"name"="voucher1"}
    }
    $recipients.Add($recipient)
}






Write-Log -message "Loaded $( $dataCsv.Count ) records"

$url = "$( $settings.base )/v2/automations/$( $automationID )/recipients"
$results = @()
if ( $recipients.Count -gt 0 ) {
    
    $chunks = [Math]::Ceiling( $recipients.count / $batchsize )

    $t = Measure-Command {
        for ( $i = 0 ; $i -lt $chunks ; $i++  ) {
            
            $start = $i*$batchsize
            $end = ($i + 1)*$batchsize - 1

            # Create body for API call
            $body = @{
                "addresses" = [System.Collections.ArrayList]@( $recipients[$start..$end] | Select * -ExcludeProperty Urn,communicationkey )
            }

            # Check size of recipients object
            Write-Host "start $($start) - end $($end) - $( $body.addresses.Count ) objects"

            # Do API call
            $bodyJson = $body | ConvertTo-Json -Verbose -Depth 20
            $result = Invoke-RestMethod -Verbose -Uri $url -Method Post -Headers $headers -ContentType $contentType -Body $bodyJson -TimeoutSec $maxTimeout
            $results += $result
            
            # Append result to the record
            for ($j = 0 ; $j -lt $result.results.Count ; $j++) {
                $singleResult = $result.results[$j] 
                if ( ( $singleResult | Get-Member -MemberType NoteProperty | where { $_.Name -eq "id" } ).Count -gt 0) {
                    # If the result contains an id
                    $recipients[$start + $j] | Add-Member -MemberType NoteProperty -Name "success" -Value 1
                    $recipients[$start + $j] | Add-Member -MemberType NoteProperty -Name "result" -Value $singleResult.id
                } else {
                    # If the results contains an error
                    $recipients[$start + $j] | Add-Member -MemberType NoteProperty -Name "success" -Value 0
                    $recipients[$start + $j] | Add-Member -MemberType NoteProperty -Name "result" -Value $singleResult.error.message

                }
                #$recipients[$start + $j].Add("result",$value)
                
            }

            # Log results of this chunk
            Write-Host "Result of request $( $result.requestId ): $( $result.queued ) queued, $( $result.ignored ) ignored"
            Write-Log -message "Result of request $( $result.requestId ): $( $result.queued ) queued, $( $result.ignored ) ignored"

        }
    }
}

# Calculate results in total
$queued = ( $results | Measure-Object queued -sum ).Sum
$ignored = ( $results | Measure-Object ignored -sum ).Sum
if ( $ignored -gt 0 ) {
    $errMessages = $results.results.error.message | group -NoElement
}

# Log the results
Write-Log -message "Queued $( $queued ) of $( $dataCsv.Count  ) records in $( $chunks ) chunks and $( $t.TotalSeconds   ) seconds"
Write-Log -message "Ignored $( $ignored ) records in total"
$errMessages | ForEach {
    $err = $_
    Write-Log -message "Error '$( $err.Name )' happened $( $err.Count ) times"
}

# Export the results
$resultsFile = "$( $uploadsFolder )$( $processId ).csv"
$recipients | select * -ExpandProperty address  -ExcludeProperty address | Export-Csv -Path $resultsFile -Encoding UTF8 -NoTypeInformation -Delimiter "`t"
Write-Log -message "Written results into file '$( $resultsFile )'"

# Remove all recipients - DEBUG
$deleted = @()
if ( $removeRecipientsAfterUpload ) {
    $results.results.id | where { $_ -ne $null } | ForEach {
        $id = $_
        $deleted += Invoke-RestMethod -Verbose -Uri "$( $settings.base )/v2/automations/$( $automationID )/recipients/$( $id )" -Method Delete -Headers $headers -ContentType $contentType
    }
    $deletedSum = ( $deleted | Measure-Object deleted -sum ).Sum
    Write-Log -message "Removed $( $deletedSum ) records"
}





If ( $queued -eq 0 ) {
    Write-Host "Throwing Exception because of 0 records"
    throw [System.IO.InvalidDataException] "No records were successfully uploaded"  
}

# return object
$return = [Hashtable]@{

    # Mandatory return values
    "Recipients"=$queued 
    "TransactionId"=$processId

    # General return value to identify this custom channel in the broadcasts detail tables
    "CustomProvider"=$moduleName
    "ProcessId" = $processId

    # Some more information for the broadcasts script
    "EmailFieldName"= $params.EmailFieldName
    "Path"= $params.Path
    "UrnFieldName"= $params.UrnFieldName

    # More information about the different status of the import
    "RecipientsIgnored" = $ignored
    "RecipientsQueued" = $queued

}

#>