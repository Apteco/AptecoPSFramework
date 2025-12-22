

# Quick start example

- [ ] PUT duck.exe into the `bin`folder or create a command for that
- [ ] update the readme here
- [ ] Add examples on how to create the scheduled task in Windows

## Configuration

```PowerShell

#-----------------------------------------------
# IMPORT THE FRAMEWORK MODULE AND EXTERNAL PLUGINS
#-----------------------------------------------

Import-Module "AptecoPSFramework"


#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = Get-Plugins | Where-Object { $_.name -eq "Apteco Cloud" }


#-----------------------------------------------
# IMPORT PLUGIN
#-----------------------------------------------

Import-Plugin $plugin.guid


#-----------------------------------------------
# LOAD THE SETTINGS (GLOBAL + PLUGIN) AND CHANGE THEM
#-----------------------------------------------

$settings = get-settings
$settings.base = "https://<account_url>/v3/REST"    # Please ask Apteco for this one
$settings.logfile = ".\file.log"
$settings.login.apikey = "username"
$settings.login.apisecret = Convert-PlaintextToSecure -String "abcdef"


#-----------------------------------------------
# SET AND EXPORT SETTINGS
#-----------------------------------------------

Set-Settings $settings
export-settings -Path ".\ae.yaml"

```

# Usage examples

```PowerShell

#-----------------------------------------------
# IMPORT PLUGIN WITH SETTINGS
#-----------------------------------------------

import-module AptecoPSFramework
import-settings ".\ae.yaml"


#-----------------------------------------------
# EXAMPLES
#-----------------------------------------------

...

```
