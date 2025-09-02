# Quickstart

This is all about the Brevo API

```PowerShell

Start-Process "powershell.exe" -WorkingDirectory "C:\Users\Florian\Downloads\Brevo"
#Set-Location -Path "C:\faststats\scripts\channels\emarsys"

# Import the module
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework" #-Verbose

#Add-PluginFolder "C:\faststats\scripts\AptecoPSPlugins"

# Choose a plugin
$plugin = get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru | Select -first 1

# Install the plugin before loading it (installing dependencies)
#Install-Plugin -Guid $plugin.guid


# Import the plugin into this session
import-plugin -Guid $plugin.guid

# Get merged settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\brevo.log"
$settings.login.apikey = Convert-PlaintextToSecure -String "12345zdsafjhgas"

# Set the settings
Set-Settings -PSCustom $settings

# Save the settings into a file
$settingsFile = ".\brevo.yaml"
Export-Settings -Path $settingsFile

```

For development purposes please make sure that you authorise your source IP address to access the API or to deactivate it. You can do this from https://app.brevo.com/security/authorised_ips

# Usual

```PowerShell
Start-Process "powershell.exe" -WorkingDirectory "C:\Users\Florian\Downloads\Brevo"
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework"
Import-Settings ".\brevo.yaml"

Get-Attribute
Get-Folder
Get-List
Get-List -FolderId 1
Add-List -Name "Abc"
Add-List -Name "Abc" -FolderId 1

# Get first batch of contacts
Get-Contact

<#
email            : florian.von.bracht@apteco.de
id               : 1
emailBlacklisted : False
smsBlacklisted   : False
createdAt        : 2024-07-12T21:37:49.586+02:00
modifiedAt       : 2024-07-12T21:41:06.063+02:00
attributes       : @{SMS=4917664787187}
listIds          : {2}
statistics       :
#>

# Get all contacts
Get-Contact -All

# Get all contacts from a specific list
Get-Contact -All -ListId 2

# Get single contact
Get-Contact -Id 1

# Get contact with campaign stats
Get-Contact -Id 1 -IncludeStats

# Show api usage
Get-ApiUsage

# Export all marketing events of the past 7 days
Add-ExportProcess -Type "marketing" -Days 7

# Get the status of that export (should be put into a loop ideally)
Get-Process -Id 123

# Get last processes
Get-Process

# Get all processes
Get-Process -All

```

# Notes

- A folder contains multiple list
- A list contains contacts
- Webhooks is used for realtime
- Exports can be done through the processes (max time for events is 7 days), a notify/webhooks url is optionally

# Webhooks

In order to use webhooks to receive events of Brevo I would recommend to setup a receiver (ask me for a scalable sample code) and then set this webhook up via a call like this

As an example, brevo webhooks need to be created through the API as the UI does not offer the batch parameter:

```PowerShell
$headers = [Hashtable]@{
    "accept" = "application/json"
    "api-key" = "xkeysib-abcdefasdfjklasdhf"
}
$body = [PSCustomObject]@{
    type    = "marketing"
    channel = "email"
    auth    = [PSCustomObject]@{
        token = "your-static-secret-token-here"
        type  = "bearer"
    }
    url     = "https://cloud.server.example/webhook/payload"
    batched = $true
    events  = @(
        "delivered"
        "opened"
        "click"
        "hardBounce"
        "softBounce"
        "unsubscribed"
        "contactUpdated"
        "contactDeleted"
        "listAddition"
        "proxyOpen"
        "spam"
    )
} | ConvertTo-Json -Depth 99

Invoke-RestMethod -Method Post -Uri "https://api.brevo.com/v3/webhooks" -ContentType "application/json" -Headers $headers -Body $body
```