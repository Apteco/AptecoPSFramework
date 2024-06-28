
# Quick start example

The documentation for the REST API can be found here: https://apidocs.inxmail.com/xpro/rest/v1/

## Configuration

```PowerShell

#-----------------------------------------------
# IMPORT THE FRAMEWORK MODULE AND EXTERNAL PLUGINS
#-----------------------------------------------

Import-Module "AptecoPSFramework"


#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = Get-Plugins | Where-Object { $_.name -like "Inxmail Professional" }


#-----------------------------------------------
# IMPORT PLUGIN
#-----------------------------------------------

Import-Plugin $plugin.guid


#-----------------------------------------------
# LOAD THE SETTINGS (GLOBAL + PLUGIN) AND CHANGE THEM
#-----------------------------------------------

$settings = get-settings
$settings.logfile = ".\inx.log"
$settings.base = "https://api.inxmail.com/<account>/rest/v1"    # Please ask Apteco for this one
$settings.login.username = ""
$settings.login.password = Convert-PlaintextToSecure -String "abcdef"


#-----------------------------------------------
# SET AND EXPORT SETTINGS
#-----------------------------------------------

Set-Settings $settings
export-settings -Path ".\inx.yaml"

```

# Usage examples

```PowerShell

#-----------------------------------------------
# IMPORT PLUGIN WITH SETTINGS
#-----------------------------------------------

import-module AptecoPSFramework
import-module C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework
import-settings ".\inx.yaml"


#-----------------------------------------------
# EXAMPLES
#-----------------------------------------------

