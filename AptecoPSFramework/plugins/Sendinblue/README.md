# Quickstart

This is all about the SendInBlue/Newsletter2Go API

```PowerShell

Start-Process "powershell.exe" -WorkingDirectory "C:\Users\Florian\Downloads\Brevo"
#Set-Location -Path "C:\faststats\scripts\channels\emarsys"

# Import the module
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework" #-Verbose

Add-PluginFolder "C:\faststats\scripts\AptecoPSPlugins"

# Choose a plugin
$plugin = get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru | Select -first 1

# Install the plugin before loading it (installing dependencies)
Install-Plugin -Guid $plugin.guid # Installs psoauth


# Import the plugin into this session
import-plugin -Guid $plugin.guid

# Get merged settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\sendinblue.log"
$settings.login.user = "test@example.org"
$settings.login.password = Convert-PlaintextToSecure -String 'abcdef'
$settings.login.authkey = Convert-PlaintextToSecure -String 'abhalsdfaldsaufzasd'
$settings.token.tokenSettingsFile = ".\sib_token.json"
$settings.token.tokenFilePath = ".\sib.token"


# Set the settings
Set-Settings -PSCustom $settings

# Save the settings into a file
$settingsFile = ".\sib.yaml"
Export-Settings -Path $settingsFile

```


# Usual

```PowerShell
Start-Process "powershell.exe" -WorkingDirectory "C:\Users\Florian\Downloads\Brevo"
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework"
Import-Settings ".\sib.yaml"

Get-Attribute
Get-Folder
Get-List

# Get first batch of contacts
Get-Contact

<#
_href                    : https://api.newsletter2go.com/recipients/il055arn
id                       : il055arn
company_id               : t8tawf3b
email                    : florian@apteco.de
modified_at              : 2024-07-17T08:55:58+0000
created_at               : 2024-07-17T08:53:52+0000
gender                   : f
first_name               : Test
last_name                : Example
num_emailbounces         : 0
is_unbouncable           : False
is_globally_unsubscribed : False
is_globally_blacklisted  : False
is_bounced               : False
import_id                : 6698e51438ab84.66296306
import_position          : 0
hash                     : 62cd577d18f42e5e9ced6068ce2540f5b674eb88a91fc5c32b5c026f6bed2c18
list_id                  : il055arn
#>

# Get all contacts
Get-Contact -Expand

# Get all contacts from a specific list
Get-Contact -ListId il055arn

# Add a list without splatting
Add-List -Name "Testlist" -HasOpenTracking -HasClickTracking

# Add a list with splatting
$addList = [Hashtable]@{
    "Name": "My new List"
    "UsesEconda" = $false
    "UsesGoogleAnalytics" = $true
    "HasOpenTracking" = $true
    "HasClickTracking" = $true
    "HasConversionTracking" = $false
    "Imprint" = "http://example.org/imprint"
    "HeaderFromEmail" = "from@example.org"
    "HeaderFromName" = "From Name"
    "HeaderReplyEmail" = "reply@example.org"
    "HeaderReplyName" = "Reply Name"
    "TrackingUrl" = ""
    "Landingpage" = "http://example.org/unsubscribe-landingpage"
    "UseEcgList" = $false
}
Add-List @addList

```
