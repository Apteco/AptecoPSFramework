

# Quickstart

This is all about the emarsys core API

```PowerShell

Start-Process "powershell.exe" -WorkingDirectory "C:\faststats\scripts\channels\emarsys"
#Set-Location -Path "C:\faststats\scripts\channels\emarsys"

# Import the module
Import-Module aptecopsframework -Verbose

Add-PluginFolder "C:\faststats\scripts\AptecoPSPlugins"

# Choose a plugin
$plugin = get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru | Select -first 1

# Install the plugin before loading it (installing dependencies)
#Install-Plugin -Guid $plugin.guid


# Import the plugin into this session
import-plugin -Guid $plugin.guid

# Get merged settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\file.log"
$settings.login.username = "apt12345"
$settings.login.secret = Convert-PlaintextToSecure -String "12345zdsafjhgas"

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
Import-Settings -Path "C:\faststats\scripts\channels\emarsys\settings.yaml"

# List all commands of this plugin
get-command -module "*emarsys*"


```


```PowerShell

# Get lists, filtered by name
get-list | where { $_.name -like "*DEMO*" }

# Count a list by id
Get-ListCount -ListId 1932108413

# Get contacts by email address, resolve fields, ignore errors (e.g. not existing email addresses)
Get-ContactData @( "florian.friedrichs@apteco.de","florian.von.bracht@apteco.de" ) -Fields "first_name", "last_name","email" -ResolveFields -IgnoreErrors

Get-ContactData -KeyValues "10596","10764","13919" -KeyId "id" -Fields "email" -IgnoreErrors

# Or via pipeline input
"10596", "10764","13919" | Get-ContactData -KeyId "id" -Fields "email" -IgnoreErrors

# Or connect the commands together
# This process is running with 1 thread. In my tests around 200k contacts need around 300 seconds to load
$c = Get-ListContact -ListId 1801153297 -all | Get-ContactData -KeyId "id" -Fields "email", "first_name" -ResolveFields -IgnoreErrors
$c | Select -First 1000 | Out-Gridview

# Select lists of the last 60 days and delete them
$regex = "_(\d{8}-\d{6})$"
get-list | Where-Object { $_.name -match $regex -and [datetime]::ParseExact($_.created, "yyyy-MM-dd HH:mm:ss", $null) -lt [datetime]::today.AddDays(-60) } | ForEach-Object {
    $listId = $_.id
    Remove-List $listId
}

```