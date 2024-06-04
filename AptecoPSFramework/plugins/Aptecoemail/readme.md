

# Quick start example

## Configuration

```PowerShell

#-----------------------------------------------
# IMPORT THE FRAMEWORK MODULE AND EXTERNAL PLUGINS
#-----------------------------------------------

Import-Module "AptecoPSFramework"


#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = Get-Plugins | Where-Object { $_.name -eq "Apteco email" }


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

# Get all contact lists
Get-ContactList

# Filter for a contactlist with a specific name like the opt in lists
Get-ContactList -Name "#OPT-IN-LIST*"

# Get contacts of a list and show them in a table
Get-Contact -ListId 338909 | Out-GridView

# Get contacts data of a list and save it as a json file (could easily be read by DuckDB)
Get-ContactData -ListId 338909 | ConvertTo-Json -Depth 99 | Set-Content -Path ".\contactdata.json" -Encoding UTF8

# Get contacts data of a list and save it as a csv file
Get-ContactData -ListId 338909 | Export-Csv -Delimiter "`t" -Encoding UTF8 -Path ".\contactdata.csv" -NoTypeInformation

# Show all fields/properties of contacts
Get-ContactMetadata

# Add a new field/property for contacts
Add-ContactMetadata -Name "Mobilnummer" -DataType "str"

# Remove a field/property for all contacts
Remove-ContactMetadata -ContactMetadataId 354972

```

## Use as preload action with Apteco FastStats Designer

- Create a settings file as json/yaml as shown above
- Create a powershell script where you want with this content (needs maybe some modifications). This could be something like `C:\Apteco\Build\20231122\Preload\load_apteco_email.ps1`

```PowerShell

# Settings
$listId = 338909
$contactFile = "C:\Apteco\Build\20231122\data\optin.csv"
$contactPropertiesFile = "C:\Apteco\Build\20231122\data\optin_properties.json"

# Load module and settings
import-module AptecoPSFramework
import-settings "C:\Apteco\Build\20231122\Preload\ae.yaml"

# Load and export data from Apteco email for contacts
Get-Contact -ListId $listId | Export-Csv -Path $contactFile -Delimiter "`t" -Encoding UTF8 -NoTypeInformation

# Load and export data from Apteco email for contacts properties ("BOM-less" json)
[System.IO.File]::WriteAllLines($contactPropertiesFile, ( Get-ContactData -ListId $listId | ConvertTo-Json -Depth 99 ))
# Use this with PowerShell Core (BOM-less by default) instead
#Get-ContactData -ListId $listId | ConvertTo-Json -Depth 99 | Set-Content -Path $contactPropertiesFile -Encoding UTF8

```

- Create a preload action in Designer like here
- Create a DuckDB database connection if you haven't done it yet. The connection string could be something like `DataSource=:memory:`. When you don't have the DuckDB database connector yet, please ask Apteco. They can send you the correct `dll` files free of charge (Open Source) to make this happen.
- Insert a query in Designer with the new DuckDB connection like

```SQL
SELECT c.*
	,p.*
FROM read_csv("C:\Apteco\Build\20231122\data\optin.csv") c
LEFT OUTER JOIN read_json_auto("C:\Apteco\Build\20231122\data\optin_properties.json") p ON c.ID = p.ContactID
```

- Then add your table to your existing datamodel