﻿function Sync-Attribute {
    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$true)][String[]]$csvAttributesNames
        ,[Parameter(Mandatory=$true)][String[]]$csvUrnFieldname
        ,[Parameter(Mandatory=$true)][String]$groupId

        ,[Parameter(Mandatory=$false)][String[]]$reservedFields = [Array]@()    # TODO [] not used yet, tags and communication key and communication_key would be good candidates
        ,[Parameter(Mandatory=$false)][String[]]$requiredFields = [Array]@()
        ,[Parameter(Mandatory=$false)][String]$responseUrnFieldname = "urn"
        ,[Parameter(Mandatory=$false)][String]$csvCommunicationKeyFieldName = "Communication Key"
        ,[Parameter(Mandatory=$false)][int]$maxAttributesCount = 40

    )

    begin {

    }

    process {

        try {


            #-----------------------------------------------
            # CHECK CSV HEADERS
            #-----------------------------------------------

            # Check if email field is present
            $equalWithRequirements = Compare-Object -ReferenceObject $csvAttributesNames.Trim().Tolower() -DifferenceObject $requiredFields.Trim().Tolower() -IncludeEqual -PassThru | Where-Object { $_.SideIndicator -eq "==" }

            if ( $equalWithRequirements.count -eq $requiredFields.Count ) {
                # Required fields are all included

            } else {
                # Required fields not equal -> error!
                throw [System.IO.InvalidDataException] "No email field present!"
            }


            #-----------------------------------------------
            # LOAD ATTRIBUTES
            #-----------------------------------------------

            # Load online attributes
            $object = "attributes"
            $globalAttributes = @( (Invoke-CR -Object $object -Method "GET" ) )
            $localAttributes = @( (Invoke-CR -Object $object -Method "GET" -Query ( [PSCustomObject]@{ "group_id" = $groupId } )) )

            # Log
            Write-Log -message "Loaded global attributes names: $( $globalAttributes.name -join ", " )"
            Write-Log -message "Loaded global attributes descriptions: $( $globalAttributes.description -join ", " )"

            #$script:pluginDebug = $localAttributes
            # Check if there is any communication key available
            If ( $localAttributes.count -gt 0 ) {

                Write-Log -message "Loaded local attributes names: $( $localAttributes.name -join ", " )"
                Write-Log -message "Loaded local attributes descriptions: $( $localAttributes.description -join ", " )"

                If ( $localAttributes.description.Trim().toLower() -notcontains $csvCommunicationKeyFieldName.Trim().toLower() ) {

                    # The default name is not present in the attributes description

                    If ( $localAttributes.description.Trim().toLower() -notcontains $csvCommunicationKeyFieldName.Trim().toLower().replace(" ","_") ) {

                        # There is also no equivalent with a technical name in the description -> Proceed with the default creation of communication key variable

                    } else {

                        # There is an equivalent with a technical name in the description -> Removing the communication key from the csv headers here so it won't get created
                        ## Adding a "virtual communication key" for compatibility for already existing integration

                        $csvAttributesNames = [Array]@( $csvAttributesNames | Where-Object { $_ -ne $csvCommunicationKeyFieldName } )

                    }

                }
            }


            # } -or $localAttributes.description.toLower() -notcontains $csvCommunicationKeyFieldName.toLower().replace(" ","_") ) {
            #     #
            # } else {
            #     If ( $localAttributes.description.toLower() -notcontains $csvCommunicationKeyFieldName.toLower() ) {
            #         # This means a communication key variable is present, but not with the name of the original communication key (normally with space)
            #         # $localAttributes += [PSCustomObject]@{
            #         #     name = $csvCommunicationKeyFieldName.ToLower().replace(" ","_")
            #         #     description = $csvCommunicationKeyFieldName
            #         # }
            #         $csvAttributesNames = [Array]@( $csvAttributesNames | where { $_ -ne $csvCommunicationKeyFieldName } )
            #     }
            # }
            # Adding a "virtual communication key" for compatibility for already existing integration
            # If ( $localAttributes.description.toLower() -notcontains $csvCommunicationKeyFieldName.toLower() ) {
            #     $localAttributes += [PSCustomObject]@{
            #         name = $csvCommunicationKeyFieldName
            #         description = $csvCommunicationKeyFieldName.ToUpper().replace(" ","_")
            #     }
            # }

            # Joining attributes
            $attributes = $globalAttributes + $localAttributes
            Write-Log -Message "You have $( $attributes.count )/$( $maxAttributesCount ) attributes now"
            If ( $attributes.count/$maxAttributesCount -gt 0.7 ) {
                Write-Log -Message "You have used more than 70% of your attributes" -Severity WARNING
            }

            # Use attributes names
            $attributesNames = @( $attributes | Where-Object { $_.name.Trim().Tolower() -notin $requiredFields.Trim().Tolower() } )


            #-----------------------------------------------
            # COMPARE COLUMNS
            #-----------------------------------------------

            # TODO [x] Now the csv column headers are checked against the description of the cleverreach attributes and not the (technical name). Maybe put this comparation in here, too. E.g. description "Communication Key" get the name "communication_key"
            #$differences = Compare-Object -ReferenceObject $attributesNames.description -DifferenceObject ( $csvAttributesNames  | where { $_.name -notin $requiredFields } ).name -IncludeEqual #-Property Name
            $differences = Compare-Object -ReferenceObject ( $attributesNames.name.Trim().Tolower() + $attributesNames.description.Trim().Tolower() ) -DifferenceObject ( $csvAttributesNames.Trim().Tolower()  | Where-Object { $_.Trim().toLower() -notin $requiredFields.Trim().Tolower() } ) -IncludeEqual #-Property Name


            #-----------------------------------------------
            # WORK OUT ATTRIBUTES TO CREATE
            #-----------------------------------------------

            #$differences = Compare-Object -ReferenceObject $attributesNames.name -DifferenceObject ( $csvAttributesNames  | where { $_.name -notin $requiredFields } ).name -IncludeEqual #-Property Name
            #$colsEqual = $differences | Where-Object { $_.SideIndicator -eq "==" }
            $colsInAttrButNotCsv = $differences | Where-Object { $_.SideIndicator -eq "<=" }
            $colsInCsvButNotAttr = $differences | Where-Object { $_.SideIndicator -eq "=>" } #-and $_.InputObject.toString() -ne $csvCommunicationKeyFieldName}


            #-----------------------------------------------
            # CHECK ATTRIBUTES COUNT
            #-----------------------------------------------

            If ( ($attributes.count + $colsInCsvButNotAttr.count) -gt $maxAttributesCount ) {
                Write-Log -Message "The max amount of attributes would be exceeded with this job. Canceling now!" -Severity ERROR
                throw [System.IO.InvalidDataException] "Too many attributes!"
                exit 0
            }


            #-----------------------------------------------
            # CHECK GLOBAL ATTRIBUTES
            #-----------------------------------------------

            If ( $csvUrnFieldname.Trim().Tolower() -ne $responseUrnFieldname.Trim().Tolower() ) {
                Write-Log "Be aware, that the response matching won't work if the urn fieldnames are not matching" -severity WARNING
            }


            #-----------------------------------------------
            # CREATE LOCAL ATTRIBUTES
            #-----------------------------------------------

            $newAttributes = [Array]@()
            $newAttributesDetails = [Array]@()
            #$Script:debug = $colsInCsvButNotAttr

            If ( @( $colsInCsvButNotAttr ).Count -gt 0 ) {
                Write-Log -Message "Creating new local attributes"
            }

            $colsInCsvButNotAttr | ForEach-Object {

                #$newAttributeName = $_.InputObject.toString()
                $att = $_.InputObject.toString()

                # Getting the right attribute regarding lower/uppercase
                $newAttributeName = $csvAttributesNames | Where-Object { $_.Trim().toLower() -eq $att }

                $body = [PSCustomObject]@{
                    "name" = $newAttributeName
                    "type" = "text"                     # text|number|gender|date
                    "description" = $newAttributeName   # optional
                    #"preview_value" = "real name"       # optional
                    #"default_value" = "Bruce Wayne"     # optional
                }

                Write-Log -Message "  Creating local attribute '$( $newAttributeName )'"
                $newAttributes += Invoke-CR -Object "groups" -Method "POST" -Path "/$( $groupId )/attributes" -Body $body #-Verbose
                #$newAttributes += Invoke-RestMethod -Uri $endpoint -Method Post -Headers $header -Body $bodyJson -ContentType $contentType -Verbose

            }

            If ( $newAttributes.count -gt 0 ) {
                Write-Log -message "Created new local attributes in CleverReach: $( $newAttributes.name.Trim().Tolower() -join ", " )" -Severity WARNING

                # Get details for new created atributes as the creation only delivers since 202309
                $newAttributesDetails = @( (Invoke-CR -Object $object -Method "GET" -Query ( [PSCustomObject]@{ "group_id" = $groupId } )) | Where-Object { $_.name.Trim().ToLower() -in $newAttributes.name.Trim().Tolower() } )


            } else {
                Write-Log -Message "No new local attributes needed to be created"
            }


            #-----------------------------------------------
            # RETURN
            #-----------------------------------------------

            [Hashtable]@{
                "global" = $globalAttributes
                "local" = $localAttributes
                "new" = $newAttributesDetails #$newAttributes
                "notneeded" = $colsInAttrButNotCsv.InputObject
            }


        } catch {

            $msg = "Failed to sync attributes"
            Write-Log -Message $msg -Severity ERROR
            Write-Log -Message $_.Exception -Severity ERROR
            throw $msg

        }

    }

    end {

    }

}