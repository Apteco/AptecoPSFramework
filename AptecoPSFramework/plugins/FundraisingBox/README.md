
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
- [x] Paging
- [x] return the data, if paging is supported

# Example script for extracting data

```PowerShell


<#

This example writes the data into a small sqlite database, but could also be just a json file 

#>

#-----------------------------------------------
# STARTUP
#-----------------------------------------------

# Go to the needed location
Set-Location "C:\faststats\Scripts\frb"

# Import module and settings
Import-Module SqlPipeline
Import-Module MergePSCustomObject
Import-Module WriteLog
Import-Module "powershell-yaml"
Import-Module AptecoPSFramework

Import-Settings ".\settings.yaml"


#-----------------------------------------------
# Load settings
#-----------------------------------------------

# Load settings from aptecopsframework and set the logfile
$s = Get-Settings
Set-Logfile -Path $s.logfile


$extractFile = ".\extract.yaml"

$minDateString = "2000-01-01 00:00:00"
$parseMinDateString = "yyyy-MM-dd HH:mm:ss"
$culture = [CultureInfo]::CreateSpecificCulture("de-DE")
$dateFormat = ("yyyy-MM-dd HH:mm:ss")

$extractSettingsDefault = [PSCustomObject]@{

    "sqliteDatabase" = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\frb.sqlite")

    "person"    = [PSCustomObject]@{
        "load" = $True
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "donation"  = [PSCustomObject]@{
        "load" = $True
        "lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)        
    }
    "mandate"   = [PSCustomObject]@{
        "load" = $False
        "lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "recurring" = [PSCustomObject]@{
        "load" = $True
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "source"    = [PSCustomObject]@{
        "load" = $True
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "tag"       = [PSCustomObject]@{
        "load" = $True
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "promoCode" = [PSCustomObject]@{
        "load" = $False
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "project"   = [PSCustomObject]@{
        "load" = $True
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "page"      = [PSCustomObject]@{
        "load" = $False
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
    }
    "type"      = [PSCustomObject]@{
        "load" = $True
        #"lastUpdate" = [DateTime]::ParseExact($minDateString, $parseMinDateString, $culture).toString($dateFormat)
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



try {


    #-----------------------------------------------
    # Open database
    #-----------------------------------------------

    Open-SQLiteConnection -DataSource $extractSettings."sqliteDatabase" -ConnectionName "default"

    # Create table if not exists
    Invoke-SqlUpdate -Query 'CREATE TABLE IF NOT EXISTS "items" ( "id" TEXT, "type" TEXT, "createdAt" TEXT, "updatedAt" TEXT, "object" TEXT )'


    #-----------------------------------------------
    # Load persons full from time to time
    #-----------------------------------------------

    $extractSettings.PSObject.Properties.Name | ForEach-Object {
        
        $m = $null
        $objectType = $_
        $objectSettings = $extractSettings.$objectType

        If ( $objectSettings.load -eq $True ) {

            Write-Log -Message "Starting with object '$( $objectType )'"

            # Load data from fundraisingbox
            Switch ( $objectType ) {

                "person" {
                    $rows = Get-Person -All
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

                "donation" {
                    $rows = Get-Donation -All -DateFrom ([datetime]::parseexact($extractSettings.donation.lastUpdate, 'yyyy-MM-dd HH:mm:ss', $null))
                    $m = $rows.created_at | Sort-Object -Unique | ForEach-Object { [datetime]::parseexact($_, 'yyyy-MM-dd HH:mm:ss', $null) } | Measure-Object -Maximum
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type and createdAt > @created" -Parameters @{"type" = $objectType; "created" = $extractSettings.$objectType.lastUpdate }
                    break
                }

                "mandate" {
                    $rows = Get-Mandate -All -DateFrom ([datetime]::parseexact($extractSettings.mandate.lastUpdate, 'yyyy-MM-dd HH:mm:ss', $null))
                    If ( $rows.Count -gt 0 ) {
                        $m = $rows.created_at | Sort-Object -Unique | ForEach-Object { [datetime]::parseexact($_, 'yyyy-MM-dd HH:mm:ss', $null) } | Measure-Object -Maximum
                        $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type and createdAt > @created" -Parameters @{"type" = $objectType; "created" = $extractSettings.$objectType.lastUpdate }
                    }
                    break
                }

                "source" {
                    $rows = Get-Source
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

                "tag" {
                    $rows = Get-Tag
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

                "promoCode" {
                    $rows = Get-PromotionCode
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

                "project" {
                    $rows = Get-Project
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

                # This is fully loaded at the moment, because there could be many changes working with the date
                "recurring" {
                    $rows = Get-Recurring -All #-NextMin ([datetime]::parseexact($extractSettings.recurring.lastUpdate, 'yyyy-MM-dd HH:mm:ss', $null))
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

                "page" {
                    $rows = Get-Page
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

                "type" {
                    $rows = Get-FrType
                    $del = Invoke-SqlUpdate -Query "DELETE FROM items WHERE type = @type" -Parameters @{ "type" = $objectType }
                    break
                }

            }
            Write-Log -Message "  Loaded $( $rows.Count ) in object '$( $objectType )'"

            If ( $rows.Count -gt 0 ) {

                # Find out the maximum id
                If ( $m -ne $null ) {
                    Write-Log -Message "  Set maximum increment to '$( $m.Maximum.toString("yyyy-MM-dd HH:mm:ss") )'"
                }

                # Remove all records
                Write-Log -Message "  Removed $( $del ) records since $( $extractSettings.$objectType.lastUpdate )"

                # Write the data into sqlite as json
                If ( (Test-SqlConnection) -eq $True ) {
                    $rows | Select-Object id, @{name="type";expression={ $objectType }}, @{name="createdAt";expression={ $_.created_at }}, @{name="updatedAt";expression={ $_.updated_at }}, @{name="object";expression={ $_ }} | Add-RowsToSql -TableName "items" -UseTransaction -FormatObjectAsJson
                }
                Write-Log -Message "  Added the rows to the database"

                # Prepare the next run
                If ( $m -ne $null ) {
                    $extractSettings.$objectType."lastUpdate" = $m.Maximum.toString("yyyy-MM-dd HH:mm:ss")
                    ConvertTo-Yaml $extractSettings -OutFile $absolutePath
                    Write-Log -Message "  Saved the new increment"
                }

            }

            # Empty the cache
            $rows = $null
            $m = $null
            $del = $null
            Write-Log -Message "  Emptied the cache"

        } else {

            Write-Log -Message "  Skipping object '$( $objectType )'"

        }

    }

} catch {

} finally {

    Close-SqlConnection

}

```

# Queries for Apteco FastStats Designer

In this example we are using the DuckDB.NET driver to query the partly nested data.

## Person

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;
WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{
"smart_contact_id": "VARCHAR"
,"birthday": "DATE"
,"company_id": "INTEGER"
,"company_name": "VARCHAR"
,"info": "VARCHAR"
,"wants_mailing": "BOOLEAN"
,"wants_no_email": "BOOLEAN"
,"wants_no_post": "BOOLEAN"
,"wants_no_call": "BOOLEAN"
,"greeting": "VARCHAR"
,"external_person_id": "VARCHAR"
,"donation_count": "INTEGER"
,"first_name": "VARCHAR"
,"last_name": "VARCHAR"
,"position": "VARCHAR"
,"salutation": "VARCHAR"
,"title": "VARCHAR"
,"created_at": "TIMESTAMP"
,"updated_at": "TIMESTAMP"
,"updated_by": "TIMESTAMP"
,"updated_by_user_id": "VARCHAR"

}') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)
SELECT id
	,unnest(extracted_list)
FROM extracted;
```



## Donation

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{

    "add_to_asset_stock": "BOOLEAN",
    "amount": "INTEGER",
    "by_recurring": "BOOLEAN",
    "created_at": "TIMESTAMP",
    "currency": "VARCHAR",
    "device_type": "VARCHAR",
    "donor_covers_the_fee_status": "VARCHAR",
    "external_donation_id": "INTEGER",
    "favourite_decade_day_of_subsequent_donations": "VARCHAR",
    "fb_fundraising_page_id": "INTEGER",
    "fb_payment_form_configuration_id": "INTEGER",
    "fb_payout_id": "INTEGER",
    "fb_person_bank_account_id": "VARCHAR",
    "fb_person_credit_card_id": "VARCHAR",
    "fb_person_id": "INTEGER",
    "fb_project_id": "INTEGER",
    "fb_recurring_payment_id": "INTEGER",
    "fb_sepa_mandate_id": "INTEGER",
    "fb_source_id": "INTEGER",
    "fb_transaction_id": "INTEGER",
    "fb_type_id": "INTEGER",
    "ident_id": "INTEGER",
    "info": "VARCHAR",
    "is_gift_donation": "INTEGER",
    "is_test": "BOOLEAN",
    "meta_info": "JSON",
    "project_promotion_code": "VARCHAR",
    "public_message": "VARCHAR",
    "public_name": "VARCHAR",
    "receipt_status": "VARCHAR",
    "receipt_type": "VARCHAR",
    "received_at": "TIMESTAMP",
    "source_name": "VARCHAR",
    "source_promotion_code": "VARCHAR",
    "status": "VARCHAR",
    "token": "VARCHAR",
    "transaction_id": "VARCHAR",
    "type_promotion_code": "VARCHAR",
    "updated_at": "TIMESTAMP",
    "waiver_of_reimbursement_of_expenses": "BOOLEAN"

}') AS extracted_list
	FROM Items
	WHERE type = 'donation'
	)
SELECT id
	,unnest(extracted_list)
FROM extracted;
```

## Recurring

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{

    "amount": "INTEGER",
    "created_at": "TIMESTAMP",
    "currency": "VARCHAR",
    "donor_covers_the_fee_status": "VARCHAR",
    "end_date": "DATE",
    "fb_payment_form_configuration_id": "INTEGER",
    "fb_person_bank_account_id": "INTEGER",
    "fb_person_credit_card_id": "INTEGER",
    "fb_person_id": "INTEGER",
    "fb_project_id": "INTEGER",
    "fb_sepa_mandate_id": "INTEGER",
    "fb_source_id": "INTEGER",
    "fb_transaction_id": "INTEGER",
    "fb_type_id": "INTEGER",
    "interval": "INTEGER",
    "is_sponsorship": "BOOLEAN",
    "is_test": "BOOLEAN",
    "meta_info": "JSON",
    "next_payment_date": "DATE",
    "project_promotion_code": "VARCHAR",
    "receipt_status": "VARCHAR",
    "source_name": "VARCHAR",
    "source_promotion_code": "VARCHAR",
    "start_date": "DATE",
    "transaction_id": "INTEGER",
    "type": "VARCHAR",
    "type_promotion_code": "VARCHAR",
    "updated_at": "TIMESTAMP"

}') AS extracted_list
	FROM Items
	WHERE type = 'recurring'
	)
SELECT id
	,unnest(extracted_list)
FROM extracted;
```


## Other Tables

### Tags

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_manual_tags'), '[{            "color": "VARCHAR",
            "description": "VARCHAR",
            "id": "INTEGER",
            "name": "VARCHAR"
}]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)
SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted;
```

### Email Addresses

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_email_addresses'), '[
        {
            "email": "VARCHAR",
            "id": "INTEGER",
            "is_main": "BOOLEAN",
            "type": "VARCHAR"
        }
    ]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)
SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted
;
```

### Phone

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_phones'), '[
        {
            "id": "INTEGER",
            "is_main": "BOOLEAN",
            "phone": "VARCHAR",
            "type": "VARCHAR"
        }
    ]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)

SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted;
```


### Addresses

This has a 1:n relationship with `Person`

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_addresses'), '[{

"id": "VARCHAR"
,"address": "VARCHAR"
,"post_code": "VARCHAR"
,"city": "VARCHAR"
,"state": "VARCHAR"
,"country": "VARCHAR"
,"type": "VARCHAR"
,"is_main": "BOOLEAN"

}]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)

SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted;
```

### Website

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_websites'), '[
        {
            "id": "INTEGER",
            "type": "VARCHAR",
            "url": "VARCHAR",
            "website_type": "VARCHAR"
        }
    ]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)

SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted
;
```

### Instant Messengers

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_instant_messengers'), '[
        {
            "id": "INTEGER",
            "messenger": "VARCHAR",
            "name": "VARCHAR",
            "type": "VARCHAR"
        }
    ]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)

SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted
;
```

## Table Lookups

### Main address

This can be used as a lookup connected to `Person`

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_addresses'), '[{

"id": "VARCHAR"
,"address": "VARCHAR"
,"post_code": "VARCHAR"
,"city": "VARCHAR"
,"state": "VARCHAR"
,"country": "VARCHAR"
,"type": "VARCHAR"
,"is_main": "BOOLEAN"

}]
') AS extracted_list
	FROM Items
	WHERE type = 'person'

	)

Select * from (
SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted)
WHERE is_main = true
;
```

### Main E-Mail Address

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_email_addresses'), '[
        {
            "email": "VARCHAR",
            "id": "INTEGER",
            "is_main": "BOOLEAN",
            "type": "VARCHAR"
        }
    ]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)
select * from (
SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted
) where is_main = True
;
```

### Main Phone

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb(READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(json_extract(OBJECT, '$.fb_person_phones'), '[
        {
            "id": "INTEGER",
            "is_main": "BOOLEAN",
            "phone": "VARCHAR",
            "type": "VARCHAR"
        }
    ]
') AS extracted_list
	FROM Items
	WHERE type = 'person'
	)
select * from(
SELECT id AS personId
	,unnest(extracted_list, recursive := true)
FROM extracted
) where is_main = True
;
```

### Project

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{
    "description": "VARCHAR",
    "goal": "INTEGER",
    "is_active": "BOOLEAN",
    "name": "VARCHAR"
}') AS extracted_list
	FROM Items
	WHERE type = 'project'
	)
SELECT id
	,unnest(extracted_list)
FROM extracted;
```

### Source

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{
"name":"VARCHAR",
"description":"VARCHAR",
"is_active": "BOOLEAN"
}') AS extracted_list
	FROM Items
	WHERE type = 'source'
	)
SELECT id
	,unnest(extracted_list)
FROM extracted;
```


### Type

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;

WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{
    "description": "VARCHAR",
    "is_active": "BOOLEAN",
    "name": "VARCHAR"
}') AS extracted_list
	FROM Items
	WHERE type = 'type'
	)
SELECT id
	,unnest(extracted_list)
FROM extracted;
```

## Variable Lookups

### Project

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;
WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{

    "name": "VARCHAR"
}') AS extracted_list
	FROM Items
	WHERE type = 'project'
	)
Select id as Code, name as Description from (
SELECT id
	,unnest(extracted_list)
FROM extracted
);

```

### Source

```SQL
INSTALL sqlite;
LOAD sqlite;
ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);
USE frb;
WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{
"name":"VARCHAR",
}') AS extracted_list
	FROM Items
	WHERE type = 'source'
	)
SELECT id as Code, name as Description from (
SELECT id
	,unnest(extracted_list)
FROM extracted
);
```

### Type

```SQL
INSTALL sqlite;


LOAD sqlite;


ATTACH 'C:\faststats\Scripts\frb\frb.sqlite' AS frb (READ_ONLY);


USE frb;


WITH extracted
AS (
	SELECT *
		,json_transform(OBJECT, '{
    "name": "VARCHAR"
}') AS extracted_list
	FROM Items
	WHERE type = 'type'
	)
Select id as Code, name as Description FROM (
SELECT id
	,unnest(extracted_list)
FROM extracted
);
```