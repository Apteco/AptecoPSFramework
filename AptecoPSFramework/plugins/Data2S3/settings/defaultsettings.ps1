[PSCustomObject]@{
    "logfile" = "C:\FastStats\Scripts\Data2Sextant\d2s.log"
    "folderToCheck" = "C:\FastStats\Publish\DB01\system\Deliveries"
    "sqlserver" = [PSCustomObject]@{
        "instance" = "localhost"
        "database" = "WS_DB01"
        "username" = "faststats_service"
        "password" = "abc" # needs to be encrypted
    }
    "duckdb" = [PSCustomObject]@{
        "Path" = "C:\FastStats\Scripts\Data2S3\bin\duckdb.exe"
        "Database" = "C:\FastStats\Scripts\Data2S3\d2s.duckdb"
    }
    "S3" = [PSCustomObject]@{
        "BucketName"    = "apteco-cloud-test"
        "AccessKey"     = "abc"
        "SecretKey"     = "xyz"  # needs to be encrypted
        "Region"        = "eu-central-1"
        "Meta" = [PSCustomObject]@{
            "UploadedBy" = "PowerShell"
            "Department" = "Apteco"
        }
    }
}