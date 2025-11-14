# Install

## Basic configuration with FastStats Designer doing the oAuth

Just replace the token `<refresh token of Designer>`, `<secret>`, `<clientid>`, `<refreshtoken>` and `<mydomain>`

```PowerShell
sl "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc"
install-module TestCredential, PSOAuth, convertunixtimestamp

#Add-PluginFolder "C:\FastStats\Scripts\AptecoPSFramework\plugins"

import-module aptecopsframework, convertunixtimestamp
#$plugin = get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru | Select -first 1
$plugin = get-plugins | where { $_.name -like "Salesforce*" }
import-plugin -Guid $plugin.guid
#install-plugin -Guid $plugin.guid

#Request-Token

# Here we do the oAuth through Designer and using the refresh token for the same access
$set = @{
    "accesstoken" = "abc" # create a dummy access token first
    "refreshtoken" = "<refresh token of Designer>"
    "tokenFile" = "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\npc.token"
    "unixtime" = Get-Unixtime
    "saveSeparateTokenFile" = $true
    "payload" = [PSCustomObject]@{
        "clientid" = "<clientid>"
        "secret" = Convert-PlaintextToSecure "<secret>"
    }
}
$json = ConvertTo-Json -InputObject $set -Depth 99  # -compress
$json | Set-Content -path "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\sf_token_settings.json" -Encoding UTF8

# Create a dummy file first
"test" | Set-Content -path "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\npc.token" -Encoding UTF8

$settings = Get-settings

$settings.base = "sandbox.my.salesforce.com" # For developer accounts, please use my.salesforce.com or develop.salesforce.com instead
$settings.instanceId = "<instanceid>"   # This is the 3 characters after the third character, so for any id like 0017R000033V6M1QAK the instance ID is 7R0
$settings.token.tokenSettingsFile = "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\sf_token_settings.json"
$settings.token.tokenFilePath = "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\npc.token"
$settings.login.refreshTokenAutomatically = $False
$settings.login.refreshtoken = "<refreshtoken>"
$settings.login."myDomain" = "<mydomain>" # something like abc--apteco
$settings.upload.errorThreshold = 30
$settings.upload.segmentVariablename = "Segment"
$settings.upload.uploadIntoSubCampaigns = $True
$settings.upload.leadExternalId = "Apteco_External_Id__c"

$settings.logfile = ".\npc.log"
Set-Settings -PSCustom $settings

$settingsFile = ".\settings.yaml"
Export-Settings -Path $settingsFile

```

## Test

```PowerShell
# Then start a new session

import-settings settings.yaml
Save-NewToken
Get-SFSCObject -Verbose

```


# Examples

```PowerShell

# The limit could also be increased or changed to `-1`
# Get all IDs from an object and delete all records
$tempFile = "c:\temp\tempfile.csv"
$d = Invoke-SFSCQuery -Query "Select Id from CampaignMember" -bulk
$l = $d | Select Id | convertto-csv -Delimiter "`t" -NoTypeInformation
[IO.File]::WriteAllLines($tempFile, $l) # Write the file with BOM
Add-BulkJob -Object CampaignMember -Operation delete -ColumnDelimiter TAB -LineEnding CRLF -Path $tempFile
Invoke-SFSCQuery -Query "Select count() from CampaignMember"

# Get a few records (even when putting the limit to 5000 it returns only 2000 records, use -bulk instead)
Invoke-SFSCQuery -Query "Select Id from CampaignMember limit 100"

# This uses bulk query and returns all data
Invoke-SFSCQuery -Query "Select Id from CampaignMember limit 100" -bulk

# Get meta data of Account object
Get-SFSCObjectMeta -Object 'Account'

# Load fields that are fillable from CampaignMember object
Get-SFSCObjectField -Object "CampaignMember" | where { $_.createable -eq $True } | Out-GridView

# Get 10 Accounts with fields Id, name where the name is like A%
Get-SFSCObjectData -Object 'Account' -Fields 'Id', 'Name' -Where "Name LIKE 'A%'" -Limit 10

# Get first 2000 contact records with all fields
Get-SFSCObjectData -Object 'Contact' -IncludeAttributes

# Get all contact records with id and firstname
Get-SFSCObjectData -Object 'Contact' -Fields "Id", "FirstName" -Bulk

# Get all fields from the Lead object and return the first 100 records
Get-SFSCObjectData -Object "Lead" -Limit 100 -Verbose

# Add a campaign
$campaign = [PSCustomObject]@{
    "Name" = "New Apteco Campaign"
    "Type" = "Email"
}
Add-SFSCObjectData -Object "Campaign" -Attributes $campaign -verbose

# List first 100 campaigns campaigns
Get-SFSCObjectData -Object "Campaign" -Fields "id", "name" -Limit 100

# Remove a created campaign by id
Remove-SFSCObjectData -Object "Campaign" -Id "701KB000000cPiiYAE"

```

# Additional hints on Salesforce NPC

In Salesforce NPC we do have accounts, that have the boolean flag `IsPersonAccount` and a Contact ID named `PersonContactId`. As the CampaignMembers object only allows contacts and leads by default, we should refer only to the ContactId and use the function `Invoke-UploadWithAccounts` rather than `Invoke-Upload` in the `upload.ps1` script at the end.

There is also an option available to activate accounts for CampaignMember. Then you need to reflect that change in the settings.

# Channel-Settings in Orbit

Besides the default settings, your integration parameters should look like this

```
settingsFile=C:\FastStats\Scripts\AptecoPSFramework\settings\npc.yaml;Operation=insert
```

and you should integrate additional variables like here

![Additional variables](https://gist.github.com/user-attachments/assets/41fa3a49-97b2-41e6-be88-34384e9a2d08)