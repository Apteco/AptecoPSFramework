
# Start

You need to setup your raisenow account with one payment provider. After that you can also create test donations. Within the setup process you will obtain a token with your client id and client secret

Documentation: https://docs.raisenow.com/api/



# Quickstart

Please make sure to change your paths and to replace `<clientid>` and `<clientsecret>`

```PowerShell

Start-Process powershell.exe -WorkingDirectory ".\Downloads\raisenow\"

# Import the module
Import-Module aptecopsframework -Verbose
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework"

# Choose a plugin
$plugin = get-plugins | Select guid, name, version, update, path | where-object { $_.name -like "RaiseNow" } | Select -first 1

# Install the plugin before loading it (installing dependencies)
#Install-Plugin -Guid $plugin.guid

# Import the plugin into this session
import-plugin -Guid $plugin.guid

# Get merged settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\file.log"
$settings.login.clientId = "<clientid>"
$settings.login.clientSecret = Convert-PlaintextToSecure "<clientsecret>"
$settings.token.tokenSettingsFile = ".\rntoken.json"

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
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework"

Import-Settings -Path ".\settings.yaml"

# List all commands of this plugin
get-command -module "*RaiseNow*"

# Get your organisations
Get-Organisation

# Get your accounts
Get-Account

# Get your subscription plans
Get-SubscriptionPlan

# List first payments
Get-Payment

# List payments since a specific unix timestamp
Get-Payment -FromUnixtime 1726049866

# List a specific payment
get-payment -Uuid "2a014f5d-098c-45b4-84b5-d431da18f98a"


```





# Notes


Token is valid for 3600 seconds



Filter for donations by creation date
https://docs.raisenow.com/partner-integrations/search/#field-inclusion-and-exclusion

```PowerShell

# Just list donations
$search = [PSCustomObject]@{
    "query" = [PSCustomObject]@{
        '$range' = [PSCustomObject]@{
            "created" = [PSCustomObject]@{
                #"lt" = "2024-04-23",
                "gt" = "1700000000" #"2024-01-01",
                #"format" = "yyyy-MM-dd"
            }
        }
    }
    "sort" = [Array]@(
        [PSCustomObject]@{
            "field" = "created"
            "field_type" = "numeric" # string|numeric|boolean
            "direction" = "asc" # asc|desc
        }
    )
    "size" = 100        # max 10k records and 10MB
    "from" = 0
    "includes" = [Array]@()
    "excludes" = [Array]@("charged_by")
}

$searchJson = ConvertTo-Json -InputObject $search -Depth 99

$payments = irm -uri "https://api.raisenow.io/search/payments" -Method Post -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"} -body $searchJson


# To count the donations after a timestamp, use this query

$search = [PSCustomObject]@{
    "query" = [PSCustomObject]@{
        '$range' = [PSCustomObject]@{
            "created" = [PSCustomObject]@{
                #"lt" = "2024-04-23",
                "gt" = "1700000000" #"2024-01-01",
                #"format" = "yyyy-MM-dd"
            }
        }
    }
    "aggs" = [PSCustomObject]@{
        "maxtimestamp" = 
            [PSCustomObject]@{
                "type" = "range"
                "field" = "created"
                "ranges"= [Array]@(
                    [PSCustomObject]@{
                        "from" = "1700000000"
                        #"to" = "1799999999"
                    }
                )
                "stats" = [PSCustomObject]@{
                    "createdstats" = "created"
                }
            }
    }
    "sort" = [PSCustomObject]@{
            "uuid" = "desc"
    }
    "size" = 0        # max 10k records and 10MB
    "from" = 0
    "includes" = [Array]@()
    "excludes" = [Array]@()
}

$searchJson = ConvertTo-Json -InputObject $search -Depth 99

$count = irm -uri "https://api.raisenow.io/search/payments" -Method Post -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"} -body $searchJson



```

Get a specific transaction/donation

```PowerShell
irm -uri "https://api.raisenow.io/payments/0b484f30-7a62-4d66-b808-a078ae158ef4" -Method Get -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"}
```

