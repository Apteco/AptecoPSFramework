

# Quickstart


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