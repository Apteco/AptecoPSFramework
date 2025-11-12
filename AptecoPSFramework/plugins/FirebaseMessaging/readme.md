# Quick start example

## Configuration

Make sure you already installed pwsh (PowerShell Core)

```PowerShell

#-----------------------------------------------
# INSTALL NEEDED PACKAGES
#-----------------------------------------------

Install-Package -Name "BouncyCastle" -Destination ".\lib"
Install-Package -Name "DuckDB.NET.Bindings.Full" -Destination ".\lib"
Install-Package -Name "DuckDB.NET.Data.Full" -Destination ".\lib"


#-----------------------------------------------
# IMPORT THE FRAMEWORK MODULE AND EXTERNAL PLUGINS
#-----------------------------------------------

Import-Module "AptecoPSFramework"


#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = Get-Plugins | Where-Object { $_.name -like "*Firebase*" }


#-----------------------------------------------
# IMPORT PLUGIN
#-----------------------------------------------

Import-Plugin $plugin.guid


#-----------------------------------------------
# LOAD THE SETTINGS (GLOBAL + PLUGIN) AND CHANGE THEM
#-----------------------------------------------

$settings = get-settings
$settings.login.serviceAccountKeyPath = "C:\FastStats\Scripts\fcm\lmobileapp-firebase-adminsdk-9abcd-abcdefghij.json"
$settings.login.projectId = "mobileapp"
$settings.upload.lockfile = "C:\temp\push.lock"
$settings.upload.maxLockfileAge = 3
$settings.upload.exclusionFolder = "C:\FastStats\Scripts\fcm\exclusions"
$settings.upload.urnFieldName = "customerid"
$settings.upload.informTokens = @("12345","56789")


#-----------------------------------------------
# SET AND EXPORT SETTINGS
#-----------------------------------------------

Set-Settings $settings
export-settings -Path ".\fcm.yaml"

```

# Usage examples

```PowerShell

#-----------------------------------------------
# IMPORT PLUGIN WITH SETTINGS
#-----------------------------------------------

import-module AptecoPSFramework
Import-Settings ".\fcm.yaml"


#-----------------------------------------------
# EXAMPLES
#-----------------------------------------------

Invoke-Push -Path 'C:\FastStats\Scripts\fcm\PushNotifications_b4782c45-6212-4cda-a57b-5645fc1cc159.txt'


```

## Use with extras.xml

Create a script with something like this

```PowerShell
Param(
     [String]$Path
    #,[String]$GenerateSerials
)
#$Path = 'C:\FastStats\Scripts\fcm\PushNotifications_b4782c45-6212-4cda-a57b-5645fc1cc159.txt'
Import-Module AptecoPSFramework
Import-Settings fcm.yaml
try {
    Invoke-Push -Path $Path
} catch {
    throw $_
    Exit 1
}
Exit 0
```

And then you can call that with an extras.xml entry like

```XML
<Extras>

...

  <SendPush>
    <runcommand>
      <command>pwsh.exe</command>
      <arguments> -ExecutionPolicy Bypass -File "C:\FastStats\Scripts\fcm\extras_sendpush.ps1" -Path "{%directory%}{%filename%}.{%ext%}"</arguments>
      <workingdirectory>C:\faststats\scripts\fcm</workingdirectory>
      <waitforcompletion>true</waitforcompletion>
    </runcommand>
  </SendPush>

...

</Extras>

```
