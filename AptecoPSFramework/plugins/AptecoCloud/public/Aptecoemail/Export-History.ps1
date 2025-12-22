




function Export-History {

    [CmdletBinding()]
    param(

        #[Parameter(Mandatory=$false)]
        #[string]$ScriptPath = "C:\FastStats\Scripts\Data2S3"
        
        #[Parameter(Mandatory=$false)][string]$HanaSettingsFile = "C:\faststats\scripts\hana\check-connection\settings.json"
        
        # String of data sources to extract
        #,[Parameter(Mandatory=$false)]
        # [String[]]$Include = [Array]@()
        
         [Parameter(Mandatory=$false)]
         [String]$StartDate = [DateTime]::Today.AddDays(-1).ToString("yyyy-MM-dd")

    )

    begin {

        # Check the input date
        Write-Log "  StartDate: $( $StartDate )"
        try {
            $tryDate = [DateTime]::ParseExact($StartDate,"yyyy-MM-dd",$null)
            Write-Log "    Date is valid"
        } catch {
            Write-Log "    Date is invalid. Exiting..." -Severity ERROR
            Exit 4
        }

        #Import-Module WriteLog, EncryptCredential, powershell-yaml, SQLPS, ImportDependency, ConvertStrings, awspowershell, MeasureRows

        $processStart = [datetime]::now
        $psEnv = Get-PSEnvironment -SkipBackgroundCheck

        #-----------------------------------------------
        # FIND OUT ABOUT 64bit
        #-----------------------------------------------

        if ($psEnv.Is64BitProcess -eq $True) {
            Write-Log "PowerShell is running in 64-bit mode."
        } else {
            Write-Log "PowerShell is running in 32-bit mode." -Severity WARNING
            Exit 4
        }


        #-----------------------------------------------
        # PREPARE SETTINGS
        #-----------------------------------------------

        # SqlServer
        $sqlParams = [Hashtable]@{
            "ServerInstance" = $Script:settings.sqlserver.instance
            "Database" = $Script:settings.sqlserver.database
            "Username" = $Script:settings.sqlserver.username
            "Password" = Convert-SecureToPlaintext -String $Script:settings.sqlserver.password
        }

        # DuckDB
        $duckDatabase = $Script:settings.duckdb.Database
        Set-Alias duckdb $Script:settings.duckdb.Path

        # AWS S3 Credentials
        $awsS3 = [hashtable]@{
            "BucketName" = $Script:settings.S3.BucketName
            "Credential" = [Amazon.Runtime.BasicAWSCredentials]::new($Script:settings.S3.AccessKey,( Convert-SecureToPlaintext -String $Script:settings.S3.SecretKey ))
            "Region" = $Script:settings.S3.Region
        }

        $metadata = @{
            'x-amz-meta-uploadedby' = $Script:settings.S3.Meta.UploadedBy
            'x-amz-meta-department' = $Script:settings.S3.Meta.Department
        }

        $processId = [guid]::NewGuid()
        $tempPath = Get-TemporaryPath
        $tempDir = New-Item -Path $tempPath -Name $processId -ItemType Directory



    }

    process {

        try {

                
            #-----------------------------------------------
            # GET RESPONSE HISTORY
            #-----------------------------------------------

            $sqlResponseHistoryQuery = Get-Content -Path ".\sql\10_response_history.sql" -Encoding utf8 -Raw

            Write-Log "Loading response history"

            $replacements = [Hashtable]@{
                "#DATE#" = $StartDate
            }
            $responseHistoryQuery = Set-Token -InputString $sqlResponseHistoryQuery -Replacements $replacements
            $responseHistoryResult = @( Invoke-Sqlcmd @sqlParams -Query $responseHistoryQuery )
            Write-Log "    Loaded $( $responseHistoryResult.Count ) records"


            #-----------------------------------------------
            # EXPORT CAMPAIGN HISTORY AS FILE
            #-----------------------------------------------

            $responseHistoryFile = Join-Path -Path $tempDir.FullName -ChildPath "responsehistory.csv"
            $responseHistoryResult | Export-Csv -Path $responseHistoryFile -Encoding utf8 -NoTypeInformation -Delimiter "`t"
            Write-Log "  Exported a file to '$( $responseHistoryFile )'"


            #-----------------------------------------------
            # CHECK THE OUTPUT
            #-----------------------------------------------

            $totalRows = Measure-Row -Path $responseHistoryFile -SkipFirstRow

            Write-Log "  The exported file contains '$( $totalRows )' rows"
            

            #-----------------------------------------------
            # CONVERT DATA TO PARQUET
            #-----------------------------------------------

            Write-Log "Using DuckDB database: $( $duckDatabase )"

            $responseHistoryParquet = Join-Path -Path $tempDir.FullName -ChildPath "responsehistory.parquet"

            Write-Log "Converting response csv data into parquet"
            $exportDuckQuery = "COPY (SELECT * FROM read_csv('$( $responseHistoryFile )')) TO '$( $responseHistoryParquet )' (FORMAT PARQUET);"

            # => Wichtig, dass bei reinen Exporten vielleicht gar nicht zum Projekt geloggt wird, sondern über einen Extra Schritt als Dateikanal
            duckdb $duckDatabase -c $exportDuckQuery


            #-----------------------------------------------
            # WRITE FILE AND UPLOAD TO S3
            #-----------------------------------------------
            

            If ( $totalRows.Count -gt 0 ) {
                $uploadKey = "history/response/$( $StartDate )/response_$( $processStart.toString("yyyyMMddHHmmss") ).parquet"
                Write-Log "Uploading file to '$( $uploadKey )'"
                Write-S3Object @awsS3 -File $responseHistoryParquet -Key $uploadKey -MetaData $metadata
            } else {
                Write-Log "The file contains 0 rows. No upload to S3."
            }


            #-----------------------------------------------
            # EXPORT CAMPAIGN METADATA AND OVERWRITE FILES
            #-----------------------------------------------

            $sqlMessageCampaignQuery = Get-Content -Path ".\sql\15_decode_message_campaign.sql" -Encoding utf8 -Raw

            Write-Log "Loading message and campaign decodes"

            $sqlMessageCampaignResult = @( Invoke-Sqlcmd @sqlParams -Query $sqlMessageCampaignQuery )
            Write-Log "  Loaded $( $sqlMessageCampaignResult.Count ) records"

            $sqlMessageCampaignFile = Join-Path -Path $tempDir.FullName -ChildPath "messagecampaign.csv"
            $sqlMessageCampaignResult | Export-Csv -Path $sqlMessageCampaignFile -Encoding utf8 -NoTypeInformation -Delimiter "`t"
            Write-Log "  Exported a file to '$( $sqlMessageCampaignFile )'"

            $uploadKey = "history/decode/messagecampaign.csv"
            Write-Log "  Uploading file to '$( $uploadKey )'"
            Write-S3Object @awsS3 -File $sqlMessageCampaignFile -Key $uploadKey -MetaData $metadata

            
            #-----------------------------------------------
            # EXPORT CHANNEL METADATA AND OVERWRITE FILES
            #-----------------------------------------------

            $sqlChannelQuery = Get-Content -Path ".\sql\16_decode_channel.sql" -Encoding utf8 -Raw

            Write-Log "Loading channel decodes"

            $sqlChannelResult = @( Invoke-Sqlcmd @sqlParams -Query $sqlChannelQuery )
            Write-Log "  Loaded $( $sqlChannelResult.Count ) records"

            $sqlChannelFile = Join-Path -Path $tempDir.FullName -ChildPath "channel.csv"
            $sqlChannelResult | Export-Csv -Path $sqlChannelFile -Encoding utf8 -NoTypeInformation -Delimiter "`t"
            Write-Log "  Exported a file to '$( $sqlChannelFile )'"

            $uploadKey = "history/decode/channel.csv"
            Write-Log "  Uploading file to '$( $uploadKey )'"
            Write-S3Object @awsS3 -File $sqlChannelFile -Key $uploadKey -MetaData $metadata



        } catch {

            $msg = "Error during process"
            Write-Log -Message $msg -Severity ERROR #-WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_

        } finally {

            #-----------------------------------------------
            # STOP TIMER
            #-----------------------------------------------

            $processEnd = [datetime]::now
            $processDuration = New-TimeSpan -Start $processStart -End $processEnd
            Write-Log -Message "Needed $( [math]::floor([int]$processDuration.TotalSeconds) ) seconds in total" -severity INFO
                    
            #Write-Log "Got $( $i ) rows. Uploaded $( $j ) records, $( $l ) failed." -severity INFO


            #-----------------------------------------------
            # REMOVE TEMP FOLDER
            #-----------------------------------------------

            Write-Log "Removing '$( $tempDir.FullName )'"
            #Remove-Item -Path $tempDir.FullName -Force -Recurse


            #-----------------------------------------------
            # CLOSE DATABASE CONNECTIONS
            #-----------------------------------------------

            #Close-DuckDBConnection

        }


    }

    end {

    }

}




