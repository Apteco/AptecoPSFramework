# Install

Just replace the token `<refresh token of Designer>`, `<secret>`, `<clientid>`, `<refreshtoken>` and `<mydomain>`

```PowerShell
sl "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc"
install-module TestCredential, PSOAuth, convertunixtimestamp

#Add-PluginFolder "C:\FastStats\Scripts\AptecoPSFramework\plugins"

import-module aptecopsframework, convertunixtimestamp
$plugin = get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru | Select -first 1
import-plugin -Guid $plugin.guid

#Request-Token

# Here we do the oAuth through Designer and using the refresh token for the same access
$set = @{
    "accesstoken" = "abc" # create a dummy access token first
    "refreshtoken" = "<refresh token of Designer>"
    "tokenFile" = "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\npc.token"
    "unixtime" = Get-Unixtime
    "saveSeparateTokenFile" = $true
    "payload" = [PSCustomObject]@{
        "clientid" = "<clientid>"
        "secret" = Convert-PlaintextToSecure "<secret>"
    }
}
$json = ConvertTo-Json -InputObject $set -Depth 99  # -compress
$json | Set-Content -path "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\sf_token_settings.json" -Encoding UTF8

# Create a dummy file first
"test" | Set-Content -path "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\npc.token" -Encoding UTF8

$settings = Get-settings

$settings.base = "sandbox.my.salesforce.com"
$settings.token.tokenSettingsFile = "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\sf_token_settings.json"
$settings.token.tokenFilePath = "C:\FastStats\Scripts\AptecoPSFramework\settings\sfnpc\npc.token"
$settings.login.refreshTokenAutomatically = $False
$settings.login.refreshtoken = "<refreshtoken>"
$settings.login."myDomain" = "<mydomain>" # something like abc--apteco

$settings.logfile = ".\npc.log"
Set-Settings -PSCustom $settings

$settingsFile = ".\settings.yaml"
Export-Settings -Path $settingsFile

```

# Test

```PowerShell
# Then start a new session

import-settings settings.yaml
Save-NewToken
Get-SFSCObject -Verbose

```