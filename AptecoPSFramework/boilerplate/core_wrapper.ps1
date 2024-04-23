################################################
#
# INPUT
#
################################################

Param(
     [String]$Verb          # Something like GetMessages
    ,[String]$InputFile     # A temporary file that is used as input for this script
    ,[String]$OutputFile    # A temporary file that is used as output for this script
)


################################################
#
# NOTES
#
################################################

<#

This script wraps all calls for PowerShell Core and is already called in pwsh

#>


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# FIND OUT CURRENT DIRECTORY
#-----------------------------------------------

$settingsFile = Get-Item -Path $params.settingsFile


#-----------------------------------------------
# PARSE INPUT JSON FILE AS HASHTABLE
#-----------------------------------------------

# -AsHashtable works since PS6
$ht = Get-Content -Path $InputFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable


#-----------------------------------------------
# WRITE HASHTABLE AS OUTPUT JSON FILE
#-----------------------------------------------

# do something
#$ht.add("abc","def")

Switch ( $Verb ) {
    "GetMessages" {
        $scriptFile = Join-Path -Path $settingsFile.DirectoryName -ChildPath "getmessages.ps1"
    }
    "GetMessageLists" {
        $scriptFile = Join-Path -Path $settingsFile.DirectoryName -ChildPath "getmessagelists.ps1"
    }
    "Preview" {
        $scriptFile = Join-Path -Path $settingsFile.DirectoryName -ChildPath "preview.ps1"
    }
    "Test" {
        $scriptFile = Join-Path -Path $settingsFile.DirectoryName -ChildPath "test.ps1"
    }
    "TestSend" {
        $scriptFile = Join-Path -Path $settingsFile.DirectoryName -ChildPath "testsend.ps1"
    }
    "Upload" {
        $scriptFile = Join-Path -Path $settingsFile.DirectoryName -ChildPath "upload.ps1"
    }
    "Broadcast" {
        $scriptFile = Join-Path -Path $settingsFile.DirectoryName -ChildPath "broadcast.ps1"
    }
    Default {
        "The verb is currently not used" # TODO [ ] create an exception instead
    }
}

# Call the corresponding script and wait for finish
. $scriptFile $ht


#-----------------------------------------------
# WRITE HASHTABLE AS OUTPUT JSON FILE
#-----------------------------------------------

$ht | ConvertTo-Json -Compress -Depth 99 | Set-Content -Path $OutputFile -Encoding UTF8
