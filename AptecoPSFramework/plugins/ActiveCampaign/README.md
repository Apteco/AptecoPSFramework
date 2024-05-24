
# General 

Documentation is available at https://developers.activecampaign.com/  

- Rate limit is 5 requests per second per account
- Pause for 1 second, if an error occures
- GET, POST, PUT and DELETE is supported


# Quickstart


```PowerShell

Start-Process "powershell.exe" -WorkingDirectory "D:\Scripts\AptecoPSFramework\ActiveCampaign"
#Set-Location -Path "C:\faststats\scripts\channels\emarsys"

# Import the module
Import-Module aptecopsframework -Verbose

Add-PluginFolder "D:\Scripts\AptecoPSFramework\Plugins"

# Choose a plugin
$plugin = get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru | Select -first 1

# Install the plugin before loading it (installing dependencies)
#Install-Plugin -Guid $plugin.guid


# Import the plugin into this session
import-plugin -Guid $plugin.guid

# Get merged settings for this plugin and change some
$settings = Get-settings

# Account specific settings
$settings.base = "https://<accountname>.api-us1.com/api/3/"
$settings.login.apikey = Convert-PlaintextToSecure -String "blablablaapikey"
$settings.logfile = ".\file.log"

# Set the settings
Set-Settings -PSCustom $settings

# Save the settings into a file
$settingsFile = ".\settings.yaml"
Export-Settings -Path $settingsFile

```

# Functions


```PowerShell

# Import the module
Import-Module aptecopsframework -Verbose
Import-Settings -Path "D:\Scripts\AptecoPSFramework\ActiveCampaign\settings.yaml"

# List all commands of this plugin
get-command -module "*ActiveCampaign*"


```

# Examples

Show all tags containing `My`

```PowerShell
Get-Tag -Search "My" 
```

Show all tags in a table

```PowerShell
Get-Tag | Out-Gridview
```

Show information about "me"

```PowerShell
Get-Me
```

Create a new tag on `contact` level

```PowerShell
New-Tag -Name "MyNewTag" -Description "This is a description"
```

Load all contacts with links

```PowerShell
Get-Contact -IncludeLinks | out-gridview
```

Get custom fields of contacts level

```PowerShell
Get-CustomField
```

Get custom fields values of contacts level

```PowerShell
Get-CustomFieldValue
```