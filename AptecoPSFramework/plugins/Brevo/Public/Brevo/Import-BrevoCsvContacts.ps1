function Import-BrevoCsvContacts {
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory = $true)]
        [String]$FilePath,

        [Parameter(Mandatory = $true)]
        [Int]$ListId,

        [Parameter(Mandatory = $false)]
        [Bool]$DisableNotification = $false,

        [Parameter(Mandatory = $false)]
        [Bool]$UpdateExistingContacts = $false,

        [Parameter(Mandatory = $false)]
        [Bool]$EmptyContactsAttributes = $false

    )

    begin {

        If ($EmptyContactsAttributes -eq $True -and $UpdateExistingContacts -eq $false) {
            Throw "If 'EmptyContactsAttributes' is set to true, 'UpdateExistingContacts' must also be true."
        }

        $returnObj = [Ordered]@{
            "ImportProcesses" = [System.Collections.ArrayList]@()
            "Info" = [PSCustomObject]@{
                "InvalidEmail" = [System.Collections.ArrayList]@()
                "DuplicateContactId" = [System.Collections.ArrayList]@()
                "DuplicateExtId" = [System.Collections.ArrayList]@()
                "DuplicateEmailId" = [System.Collections.ArrayList]@()
                "DuplicatePhoneId" = [System.Collections.ArrayList]@()
                "DuplicateWhatsappId" = [System.Collections.ArrayList]@()
                "DuplicateLandlineNumberId" = [System.Collections.ArrayList]@()
            }
        }

    }

    process {


        $importProcesses = [System.Collections.ArrayList]@()

        if (-not (Test-Path $FilePath)) {
            throw "File '$( $FilePath )' does not exist."
        }

        $maxChunkSize = 8MB
        $encoding = [System.Text.Encoding]::UTF8

        Write-Log "Opening CSV file '$( $FilePath )' for reading and uploading in chunks of max $( $maxChunkSize / 1MB ) MB..."

        $reader = [System.IO.StreamReader]::new($FilePath, $encoding)
        try {
            $header = $reader.ReadLine()
            if (-not $header) {
                throw "CSV file is empty."
            }

            $chunkLines = @($header)
            $currentSize = $encoding.GetByteCount("$header`r`n")

            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                $lineSize = $encoding.GetByteCount("$line`r`n")

                if (($currentSize + $lineSize) -gt $maxChunkSize) {

                    Write-Log "Uploading chunk of size $( [math]::round(($currentSize / 1MB), 5) ) MB..."

                    # Upload current chunk
                    $csvChunk = $chunkLines -join "`r`n"
                    $params = [Hashtable]@{
                        "Object" = "contacts/import"
                        "Method" = "POST"
                        "Body"   = [PSCustomObject]@{
                            "fileBody"                = $csvChunk
                            "listIds"                 = @($ListId)
                            "disableNotification"     = $DisableNotification
                            "updateExistingContacts"  = $UpdateExistingContacts
                        }
                    }
                    if ($updateExistingContacts -eq $true) {
                        $params.Body | Add-Member -MemberType NoteProperty -Name "emptyContactsAttributes" -Value $EmptyContactsAttributes
                    }
                    $importProcessId = Invoke-Brevo @params
                    $importProcesses.Add(( $importProcessId )) | out-null

                    Write-Log "Chunk uploaded with processid $( $importProcessId.processId ), starting new chunk..."

                    # Start new chunk
                    $chunkLines = @($header, $line)
                    $currentSize = $encoding.GetByteCount("$header`r`n$line`r`n")
                } else {
                    $chunkLines += $line
                    $currentSize += $lineSize
                }
            }

            # Upload any remaining lines
            if ($chunkLines.Count -gt 1) {

                Write-Log "Uploading chunk of size $( [math]::round(($currentSize / 1MB), 5) ) MB..."

                $csvChunk = $chunkLines -join "`r`n"
                $params = [Hashtable]@{
                    "Object" = "contacts/import"
                    "Method" = "POST"
                    "Body"   = [PSCustomObject]@{
                        "fileBody"                = $csvChunk
                        "listIds"                 = @($ListId)
                        "disableNotification"     = $DisableNotification
                        "updateExistingContacts"  = $UpdateExistingContacts
                    }
                }
                if ($updateExistingContacts -eq $true) {
                    $params.Body | Add-Member -MemberType NoteProperty -Name "emptyContactsAttributes" -Value $EmptyContactsAttributes
                }
                $importProcessId = Invoke-Brevo @params
                $importProcesses.Add(( $importProcessId )) | out-null

                Write-Log "Chunk uploaded with processid $( $importProcessId.processId )."
            }
        } finally {
            $reader.Close()
        }

        # Now check the import status
        Write-Log "Checking import status of $( $importProcesses.Count ) processes..."

        # TODO add a timeout here
        $allImportsCompleted = $false
        while (-not $allImportsCompleted) {

            # Create a list to hold processes to remove
            $processesToRemove = @()

            foreach ($importProcess in $importProcesses) {
                $updatedImportProcess = Get-Process -Id $importProcess.processId

                if ($updatedImportProcess.status -in @("completed", "error", "aborted")) {

                    $returnProcess = [Ordered]@{
                        "ProcessId" = $importProcess.processId
                        "Status"    = $updatedImportProcess.status
                    }

                    $returnObj.ImportProcesses.Add([PSCustomObject]$returnProcess) | Out-Null

                    Write-Log "Import process $($importProcess.processId) completed with status '$($updatedImportProcess.status)'."

                    # Add results to the return object
                    $updatedImportProcess.Info.Import.invalid_emails | Where-Object { $_ -ne $null } | ForEach-Object {
                        $returnObj.Info.InvalidEmail.AddRange([Array]@( Invoke-RestMethod -Uri $_ -Method Get | ConvertFrom-Csv -Delimiter ";" )) | Out-Null # TODO possibly add proxy here                        
                    }
                    $updatedImportProcess.Info.Import.duplicate_contact_id | Where-Object { $_ -ne $null } | ForEach-Object {
                        $returnObj.Info.DuplicateContactId.AddRange([Array]@( Invoke-RestMethod -Uri $_ -Method Get | ConvertFrom-Csv -Delimiter ";" )) | Out-Null # TODO possibly add proxy here                        
                    }
                    $updatedImportProcess.Info.Import.duplicate_ext_id | Where-Object { $_ -ne $null } | ForEach-Object {
                        $returnObj.Info.DuplicateExtId.AddRange([Array]@( Invoke-RestMethod -Uri $_ -Method Get | ConvertFrom-Csv -Delimiter ";" )) | Out-Null # TODO possibly add proxy here                        
                    }
                    $updatedImportProcess.Info.Import.duplicate_email_id | Where-Object { $_ -ne $null } | ForEach-Object {
                        $returnObj.Info.DuplicateEmailId.AddRange([Array]@( Invoke-RestMethod -Uri $_ -Method Get | ConvertFrom-Csv -Delimiter ";" )) | Out-Null # TODO possibly add proxy here                        
                    }
                    $updatedImportProcess.Info.Import.duplicate_phone_id | Where-Object { $_ -ne $null } | ForEach-Object {
                        $returnObj.Info.DuplicatePhoneId.AddRange([Array]@( Invoke-RestMethod -Uri $_ -Method Get | ConvertFrom-Csv -Delimiter ";" )) | Out-Null # TODO possibly add proxy here                        
                    }
                    $updatedImportProcess.Info.Import.duplicate_whatsapp_id | Where-Object { $_ -ne $null } | ForEach-Object {
                        $returnObj.Info.DuplicateWhatsappId.AddRange([Array]@( Invoke-RestMethod -Uri $_ -Method Get | ConvertFrom-Csv -Delimiter ";" )) | Out-Null # TODO possibly add proxy here                        
                    }
                    $updatedImportProcess.Info.Import.duplicate_landline_number_id | Where-Object { $_ -ne $null } | ForEach-Object {
                        $returnObj.Info.DuplicateLandlineNumberId.AddRange([Array]@( Invoke-RestMethod -Uri $_ -Method Get | ConvertFrom-Csv -Delimiter ";" )) | Out-Null # TODO possibly add proxy here                        
                    }

                    $processesToRemove += $importProcess

                } else {
                    Write-Log "Import process $($importProcess.processId) is still in status '$($updatedImportProcess.status)'."
                }
            }

            # Remove the completed processes after the iteration
            foreach ($processToRemove in $processesToRemove) {
                $importProcesses.Remove($processToRemove) | Out-Null
            }


            # Check if there are any remaining import processes
            if ($importProcesses.Count -eq 0) {
                $allImportsCompleted = $true
                Write-Log "All import processes completed."
            }

            # Wait before checking again
            if (-not $allImportsCompleted) {
                Start-Sleep -Seconds 30
            }

        }

    }

    end {

        # return
        [PSCustomObject]$returnObj

    }
    
}