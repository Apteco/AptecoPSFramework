
# Quickstart

This is all about the emarsys core API

```PowerShell

Start-Process "powershell.exe" -WorkingDirectory "C:\faststats\Scripts\frb"
#Set-Location -Path "C:\faststats\scripts\channels\emarsys"

# Import the module
Import-Module aptecopsframework -Verbose
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework" -Verbose


# Choose a plugin
$plugin = get-plugins | Select guid, name, version, update, path | Out-GridView -PassThru | Select -first 1

# Install the plugin before loading it (installing dependencies)
#Install-Plugin -Guid $plugin.guid


# Import the plugin into this session
import-plugin -Guid $plugin.guid

# Get merged settings for this plugin and change some
$settings = Get-settings
$settings.logfile = ".\file.log"
$settings.login.token = Convert-PlaintextToSecure -String "12345zdsafjhgas"

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
Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework" -Verbose
Import-Settings -Path "C:\faststats\scripts\frb\settings.yaml"

# List all commands of this plugin
get-command -module "*FundraisingBox*"


```


```PowerShell

# Get first 10 donations
Get-Donation

# Get first 20 donations
Get-Donation -First 20

# Get all donations
Get-Donation -All

# Get a specific donation with an id
Get-Donation -Id 23885335



# Get the first 10 persons and format as a table
get-person | ft

# Get the first 20 persons
Get-Person -First 20

# Get all persons
Get-Person -All

# Get a specific person with an id
Get-Person -Id 23885335

# Get all projects
get-project | ft

<#

    id name    description goal is_active
    -- ----    ----------- ---- ---------
112588 Affe                   0      True
112589 Klima                  0      True
112590 Umwelt                 0      True
112591 Elefant                0      True
112592 Medizin                0      True

#>



# Get all tags
Get-Tag

<#

   id name          description color
   -- ----          ----------- -----
81215 Spender                   grass
81216 Dienstleister             orange
81217 Dauerspender              yellow
81218 Freiwilliger              teal
81219 Unternehmer               blue
81220 Presse                    blue

#>

# Get all pages of persons
Get-Page

# Get all payouts
Get-Payout

# Get all sources
Get-Source

<#

   id name            description                                                 is_active
   -- ----            -----------                                                 ---------
    2 Spendenaktionen Diese Spende erreichte Sie über das Spendenaktion Add-on         True
    3 Formular        Diese Spende erreichte Sie über das Zahlungsformular Add-on      True
24062 Kollekte                                                                         True
24063 Sommerfest                                                                       True
24064 Telefonakquise                                                                   True

#>

# Get all recurring donations
Get-Recurring

# Get all receipts
Get-Receipt

# Get all promotion codes
Get-PromotionCode

# Get all sepa mandates
Get-Mandate

# Get all types - this has another name because of the already existing PowerShell function named Get-Type
Get-FrType

<#

   id name                description is_active
   -- ----                ----------- ---------
    3 PayPal                               True
   15 Wikando Lastschrift                  True
16213 Barspende                            True
16214 Überweisung                          True

#>

```

# Other notes

Predefined values can be found here: https://developer.fundraisingbox.com/reference/predefined-values

# TODO

- [ ] Mark all functions with needed packages to license
- [ ] Paging
- [ ] return the data, if paging is supported

# Example script for extracting data

```PowerShell


<#

This example writes the data into a small sqlite database, but could also be just a json file 

#>

#-----------------------------------------------
# STARTUP
#-----------------------------------------------

# TODO Implement logging

# Go to the needed location
Set-Location "C:\faststats\Scripts\frb"

# Import module and settings
#Import-Module SimplySql
Import-Module SqlPipeline
Import-Module MergePSCustomObject
Import-Module WriteLog
Import-Module "powershell-yaml"

Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework"
#Import-Module AptecoPSFramework
Import-Settings ".\settings.yaml"


#-----------------------------------------------
# Load settings
#-----------------------------------------------

$extractFile = ".\extract.yaml"

$culture = [CultureInfo]::CreateSpecificCulture("de-DE")
$dateFormat = ("yyyy-MM-dd HH:mm:ss")

$extractSettingsDefault = [PSCustomObject]@{

    "sqliteDatabase" = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\frb.sqlite")

    "person"    = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "donation"  = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "mandate"   = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "recurring" = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "source"    = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "tag"       = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "promoCode" = [PSCustomObject]@{
        "load" = $False
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "project"   = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "page"      = [PSCustomObject]@{
        "load" = $False
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
    "type"      = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact("2000-01-01 00:00:00","yyyy-MM-dd HH:mm:ss",$culture).toString($dateFormat)
    }
}


#-----------------------------------------------
# Load past max increment values and merge with settings
#-----------------------------------------------

# Resolve path first
$absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($extractFile)

# Load file
If (( Test-Path -Path $absolutePath ) -eq $True) {

    # Load the files and merge the settings
    $existingSettings = Get-Content -Path $absolutePath -Encoding utf8 -Raw | ConvertFrom-Yaml | ConvertTo-Yaml -JsonCompatible | ConvertFrom-Json

} else {

    $existingSettings = [PSCustomObject]@{"dummy"="value"}

}

$extractSettings = Merge-PSCustomObject -Left $extractSettingsDefault -Right $existingSettings -MergePSCustomObjects #-MergeHashtables -AddPropertiesFromRight


#-----------------------------------------------
# Open database
#-----------------------------------------------

Open-SQLiteConnection -DataSource $extractSettings."sqliteDatabase" -ConnectionName "default"

# Create table if not exists
Invoke-SqlUpdate -Query 'CREATE TABLE IF NOT EXISTS "items" ( "id" TEXT, "type" TEXT, "createdAt" TEXT, "updatedAt" TEXT, "object" TEXT )'

try {

    #-----------------------------------------------
    # Load persons
    #-----------------------------------------------

    If ( $extractSettings.person.load -eq $True ) {

        # Get person data
        $objectType = "person"
        $rows = Get-Person -All -DateFrom ([datetime]::parseexact($extractSettings.person.lastUpdate, 'yyyy-MM-dd HH:mm:ss', $null))

        # Find out the maximum id
        $m = $rows.updated_at | Sort-Object -Unique | ForEach-Object { [datetime]::parseexact($_, 'yyyy-MM-dd HH:mm:ss', $null) } | Measure-Object -Maximum
        
        # Remove all records greater than the current timestamp (ensures clean data, if reset)
        Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type and updatedAt > @updated" -Parameters @{"type" = $objectType; "updated" = $extractSettings.person.lastUpdate }

        # Write the data into sqlite as json
        If ( (Test-SqlConnection) -eq $True ) {
            $rows | Select-Object id, @{name="type";expression={ $objectType }}, @{name="createdAt";expression={ $_.created_at }}, @{name="updatedAt";expression={ $_.updated_at }}, @{name="object";expression={ $_ }} | Add-RowsToSql -TableName "items" -UseTransaction -FormatObjectAsJson
        }

        # Prepare the next run
        $extractSettings."person"."lastUpdate" = $m.Maximum.toString("yyyy-MM-dd HH:mm:ss")
        ConvertTo-Yaml $extractSettings -OutFile $absolutePath

        # Empty the cache
        #$rows = $null
        #$m = $null

    }

    <#
    Get-Donation -All
    Get-Mandate -All
    Get-Recurring -All

    #>


    #-----------------------------------------------
    # Load full objects every time
    #-----------------------------------------------

    <#
    Get-Source
    Get-Tag
    #Get-PromotionCode
    Get-Project
    #Get-Page
    Get-FrType
    #>



} catch {

} finally {

    Close-SqlConnection

}

```