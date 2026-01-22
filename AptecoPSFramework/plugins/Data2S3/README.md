
# Installation on Cloud Server

## Preparation

Make sure you open the powershell window with the user you are running the scheduled task with


```PowerShell

#-----------------------------------------------
# SET LOCATION FOR THE SETTINGS AND LOG
#-----------------------------------------------

Set-Location "C:\FastStats\Scripts\Data2S3"


#-----------------------------------------------
# IMPORT THE FRAMEWORK MODULE AND EXTERNAL PLUGINS
#-----------------------------------------------

Import-Module AptecoPSFramework


#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = Get-Plugins | Where-Object { $_.name -eq "Data2S3" }


#-----------------------------------------------
# IMPORT PLUGIN
#-----------------------------------------------

import-plugin -Guid $plugin.guid

#-----------------------------------------------
# LOAD THE SETTINGS (GLOBAL + PLUGIN) AND CHANGE THEM
#-----------------------------------------------

$settings = Get-settings
$settings.logfile = ".\file.log"
$settings.sqlserver.username = "abc"
$settings.sqlserver.password = Convert-PlaintextToSecure -String "def"
$settings.duckdb.Path = "C:\FastStats\Scripts\Data2S3\bin\duckdb.exe"
$settings.duckdb.Database = "C:\FastStats\Scripts\Data2S3\d2s.duckdb"
$settings.S3.BucketName = "bucketname"
$settings.S3.AccessKey = "s3key"
$settings.S3.SecretKey = "s3secret"

#-----------------------------------------------
# SET AND EXPORT SETTINGS
#-----------------------------------------------

Set-Settings -PSCustom $settings
Export-Settings -Path ".\d2s3.yaml"

```

Make sure, that if you use the folder `C:\FastStats\Scripts\Data2S3` that you create a subfolder named `bin` and put the current `duckdb.exe` in there. You can download it here: https://duckdb.org/install/?platform=windows&environment=cli



## Daily tasks

This needs to run where the response data lies in a SQLServer database. You can use `pwsh` or `powershell` to run it

Run the script then automatically one time per day with task scheduler

```PowerShell
Set-Location "C:\FastStats\Scripts\Data2S3"
Import-Module AptecoPSFramework
Import-Settings ".\d2s3.yaml"
Export-History
```

# Integration into FastStats Designer

## DuckDB Provider

Just ask Apteco to provide the current DuckDB .NET provider and put it in your Designer installation folder.

## Create credentials for your S3 storage

Create a credential in Designer for a database and add a DuckDB credential with this connection string:

```
DataSource=:memory:;
```

Then add a database data source and choose `Custom Query`, fill out your credentials in the following SQL and execute it. It should return a `true`:

```SQL
install httpfs;
load httpfs;

CREATE OR REPLACE PERSISTENT SECRET secret1 (
    TYPE S3,
    PROVIDER config,
    KEY_ID '#YOURS3KEY#',
    SECRET '#YOURS3SECRET#',
    REGION 'eu-central-1'
);
```

After that you can erase that query as the secret is encrypted and stored permanent in your duckdb storage. As an alternative you could also use your aws credential storage through Powershell.

## Read parquet through custom queries

Now you can access the s3 storage. Just replace `#S3BUCKETNAME#` and read the data

```
install httpfs;
load httpfs;
-- more options are here: https://duckdb.org/docs/data/csv/overview
with t as (

SELECT *
FROM read_parquet('s3://#S3BUCKETNAME#/history/response/**/*.parquet', union_by_name = true, filename = true)

)

SELECT t1.*
FROM t as t1
```

Then connect the `urn` or `agenturn` column with your main primary key. 

In `Define Variables` you can use the following queries to resolve some keys into something readable and Selector variables

```SQL
SELECT Code, Description
FROM read_csv('s3://#S3BUCKETNAME#/history/decode/channel.csv')
ORDER BY Code
```

```SQL
SELECT DISTINCT "CampaignId" as Code, "CampaignDesc" as Description
FROM read_csv('s3://#S3BUCKETNAME#/history/decode/messagecampaign.csv')
ORDER BY "CampaignId"
```

```SQL
SELECT DISTINCT "MessageId" as Code, "MessageDesc" as Description
FROM read_csv('s3://#S3BUCKETNAME#/history/decode/messagecampaign.csv')
ORDER BY "MessageId"
```

Then add the variables to your folders and optionally you could create an index for response data in your post load actions.