[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/PlagueHO/PSAuth/blob/dev/LICENSE)


# Apteco Customs - AptecoPSFramework

This framework is mainly created for installing and using custom channels in Apteco Orbit and PeopleStage. The channel implementations are written in PowerShell and already implemented as "Plugins" in this module. But there is a function implemented so you can refer to your own channels that are not getting overwritten if you update this module. The development of this module is done here, but it is published through [PowerShell Gallery](https://www.powershellgallery.com/packages?q=%23apteco).

# Current integrations/plugins

Type|Vendor|API name|Technology|Features
-|-|-|-|-
Email|CleverReach|v3|REST|Tagging, Upload, Broadcast-Preparation, Broadcast, Receiver- and Response-Download
CRM|SalesForce SalesCloud|REST/Bulk API|REST|Load CRM Data, Upload to CampaignMembers
CRM|Hubspot|CRM API v3|REST|Download all CRM object data full/delta, Upload to Marketing Lists
CRM|Microsoft Dynamics 365 CRM|DataVerse oData WebAPI|REST|Download all CRM object data and picklists full/delta

# Installation / Update / Uninstall

This has been put into the wiki: https://github.com/Apteco/AptecoPSFramework/wiki/Installation-and-Update



# Getting started with the Framework

After the installation you are reade to use this module and create a settings json file and connect that with your Apteco system. So please import your module like 

```PowerShell
Import-Module AptecoPSFramework -Verbose
```

If you get error messages during the import, that is normal, because there are modules missing yet. They need to be installed with `Install-AptecoPSFramework`

Please go ahead to a directory where the script files should be placed like `D:\Scripts\AptecoPSFramework`. Then you can now start the installation

```PowerShell
Install-AptecoPSFramework -Verbose
```

This command installs dependencies like scripts, modules and nuget packages. After installing the dependencies it copies a "Boilerplate" into your current directory and gives you more hints about how to connect this "Boilerplate" with a PeopleStage PowerShell channel.





Now you should find a `create_settings.ps1` file in your boilerplate folder. Please execute this one to create a new `settings.json` file with

```PowerShell
. .\create_settings.ps1
```




# Getting started with Plugins

You are able to use already integrated plugins, but can also develop your own plugins and load it via this module and use the already existing framework with logging, error handling, encryption and much more comfort. The idea is to have a `settings.json` which can also have a different name. That file contains all information to drive the module and integration with Apteco. You can have as many settings files for the same or different plugins as you want.

Please consider to create a channel multiple times, e.g. for every table level.

## Create your settings json/yaml file

The first target is to create your settings json file, because that contains all the information that the module needs for being triggered by PeopleStage. In the boiletplate you can find a rough example of how to create that file. But specific for the chosen plugins you can set more or less parameters. They can be changed through that `create_settings.ps1` script or later in your json file. It depends on how often you change the settings json file. This path to the settings file json needs to be exchanged in the channel editor settings in the integration parameter. This needs to be an absolute path.

Tool tip: If you want to visualise (and edit) the JSON, this tool can help: https://jsoncrack.com/editor

```PowerShell

#-----------------------------------------------
# IMPORT THE FRAMEWORK MODULE
#-----------------------------------------------

Import-Module "AptecoPSFramework"


#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = @(, (get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru ))

If ($plugin.count -gt 1) {
    Write-Host "Sorry, you have chosen more than 1 plugin"
    exit 1
} elseif ( $plugin.count -eq 0 ) {
    Write-Host "Sorry, you have chosen less than 1 plugin"
    exit 1
}


#-----------------------------------------------
# LOAD THE PLUGIN
#-----------------------------------------------

Import-Plugin -guid $plugin.guid


#-----------------------------------------------
# LOAD THE SETTINGS (GLOBAL + PLUGIN)
#-----------------------------------------------

$settings = Get-settings
#$settings.pluginGuid = $plugin.guid


#-----------------------------------------------
# CHANGE PARAMETERS
#-----------------------------------------------

$settings.logfile = ".\file.log"

# Specific for CleverReach just as an example, it is commented out currently
<#
$settings.token.tokenUsage = "consume"
$settings.token.tokenFilePath = "D:\Scripts\CleverReach\check-token\cr.token"
#>


#-----------------------------------------------
# SET AND EXPORT SETTINGS
#-----------------------------------------------

Set-Settings -PSCustom $settings
Export-Settings -Path ".\settings.yaml"
```


## Create your own plugin or change an existing one

These steps are needed

1. Get a copy of the demo plugin as a template or get another plugin from this modules folder
1. Open the `Plugin.ps1` and exchange the guid with a new random one like `[guid]::NewGuid().ToString()`
1. Go through the different files and change the code. Please be aware to not touch the functions names in the `peoplestage` folder


Please have a look at the [Demo channel](plugins/Demo) as a kind of template/boilerplate to start with. The guid needs to be changed in the `Plugin.ps1` to allow loading the plugin, but that is explained later.

Please note that the plugin that gets dynamically created when calling `import-plugin`, a copy of the internal variables is used. So after `import-plugin` all changes in the imported module don't have an effect to the dynamic plugin.

Please think about a [pull request](https://github.com/Apteco/AptecoPSModules/pulls) if you want to add more integrations into this repository

The structure for the plugin folder should look like this

Mandatory|Folder|Filename|Description
-|-|-|-
yes|.|ReadMe.md|Description about this plugin
yes|.|Plugin.ps1|Metadata about the plugin. The filename should always be `Plugin.ps1`. If you create a new plugin, the guid needs to be recreated. Output a new guid with `[guid]::newGuid().toString()`
yes|./settings|defaultsettings.ps1|These settings are plugin dependent and will be merged with the overall settings
no|./public/setup|install-plugin.ps1|This script does a plugin dependent installation
no|./public/peoplestage|test-login.ps1|Script to test the login via channel editor
yes|./public/peoplestage|get-messages.ps1|Script to load messages
no|./public/peoplestage|get-groups.ps1|Script to load groups or lists
yes|./public/peoplestage|invoke-upload.ps1|Script to upload records into a group or list
no|./public/peoplestage|invoke-broadcast.ps1|Script to trigger/broadcast a message (not needed for "upload only")
no|./public/peoplestage|show-preview.ps1|Script to render a message as html

Generally the `private` folder is for internal functions that are used by the plugin, but are not usable in your PowerShell session. The `public` folders functions are exported to your sessions, which means you can use them as CmdLets automatically after the plugin has been loaded.


### Loading your plugin

You do not need to put the plugin back to the modules folders, otherwise it can be deleted or overwritten with an update. Use this command to define your own plugins root directory after `Import-Module AptecoPSFramework`

```PowerShell
Add-PluginFolder -Folder "C:\temp\plugins"
Register-Plugins
```

After you have added the directory and re-registered all plugins you should see a combination of the default plugins and your new developed one with

```PowerShell
Get-Plugins
```

After you have seen the list of plugins there are multiple ways to choose one manually with an `Get-Plugins | Out-GridView -PassThrough` or just copy the guid. Choose the plugin for the module with something similar like

```PowerShell
Import-Plugin -guid "07f5de5b-1c83-4300-8f17-063a5fdec901"
```

### Use plugin specific functionality

There are default functionalities per plugin like `get-messages`, `invoke-upload` etc. But there are maybe more functionalities that could be useful. To use this you can find in the `Plugin.ps1` a class, that is automatically loaded into the module, when importing the plugin. So you could do something like

```PowerShell
Import-Module AptecoPSFramework -Verbose
Set-DebugMode -DebugMode $true          # Not necessarily needed, only for testing purposes
Import-Settings -Path ".\settings.json" # The plugin gets automatically loaded from the json file

# Now you can execute plugin specific commands you can see with
Get-Module | Format-List

# And get a result like
<#

Name              : AptecoPSFramework
Path              : D:\Scripts\PSModules\AptecoPSFramework\AptecoPSFramework.psm1
Description       : Apteco PS Modules - Framework
ModuleType        : Script
Version           : 0.0.1
NestedModules     : {WriteLog, MeasureRows, EncryptCredential, ExtendFunction...}
ExportedFunctions : {Add-PluginFolder, Export-Settings, Get-Debug, Get-Plugin...}
ExportedCmdlets   :
ExportedVariables :
ExportedAliases   :

Name              : Invoke CleverReach
Path              : D:\scripts\CleverReach\PSCleverReachModule\f5c74d5e-a3db-46d9-a0f4-51edf2a79e6b
Description       :
ModuleType        : Script
Version           : 0.0
NestedModules     : {WriteLog, MeasureRows, EncryptCredential, ExtendFunction...}
ExportedFunctions : {Get-Groups, Get-Messages, Invoke-Broadcast, Invoke-Upload...}
ExportedCmdlets   :
ExportedVariables :
ExportedAliases   :

#>

# Here is another example to list all functions
get-module | where { $_.Name -like "Invoke*" } | Select Name -ExpandProperty ExportedFunctions

# Which generates this output
<#

Key              Value
---              -----
Get-Groups       Get-Groups
Get-Messages     Get-Messages
Invoke-Broadcast Invoke-Broadcast
Invoke-Upload    Invoke-Upload
Show-Preview     Show-Preview
Test-Login       Test-Login
Test-Send        Test-Send

#>
```


# Errors

## Die Eingabezeichenfolge hat das falsche Format

When you get this error

```PowerShell
PS C:\Users\Administrator> find-module aptecopsframework -IncludeDependencies -AllVersions
Der Wert "0.0.17-alpha" kann nicht in den Typ "System.Version" konvertiert werden. Fehler: "Die Eingabezeichenfolge
hat das falsche Format."
```

Please install a newer version of `PowerShellGet`

```PowerShell
Install-Module PowerShellGet -Force -AllowClobber
```

## Channel not working after update

Please restart your FastStats service if you have problems after an update.

## Unable to get messages with Exception / Unable to get lists with Exception

This should not happen, but shows that your PSModulePath cannot be loaded properly from C# runspaces.

To manually fix this, just add `C:\Program Files\WindowsPowerShell\Modules` to the system environment variable `PSModulePath`


## DuckDB cannot be opened

Since 0.3.0 there is DuckDB integrated in this framework. If you have problems to get it work like

```PowerShell
Import-Module AptecoPSFramework
Open-DuckDBConnection
```

and it fails with something like

```PowerShell
PS C:\Users\WDAGUtilityAccount> Open-DuckDBConnection
Exception calling "Open" with "0" argument(s): "The type initializer for
'DuckDB.NET.Data.DuckDBConnectionStringBuilder' threw an exception."
At C:\Users\WDAGUtilityAccount\Downloads\AptecoPSFramework\public\duckdb\Open-DuckDBConnection.ps1:18 char:13
+             $Script:duckDb.Open()
+             ~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : TypeInitializationException
```

then you need to install the newest version of `vcredist` from: https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170

If you already have installed the AptecoPSFramework, make sure to re-install the dependencies in your settings file directory with `Install-AptecoPSFramework`