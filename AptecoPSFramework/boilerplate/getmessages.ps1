﻿
################################################
#
# INPUT
#
################################################

[CmdletBinding(DefaultParameterSetName='HashtableInput')]
Param(

    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='HashtableInput')]
    [hashtable]$params,

    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='JsonInput')]
    [String]$jsonParams

)

# If this script is called by itself, re-transform the escaped json string input back into a hashtable
If ( $PsCmdlet.ParameterSetName -eq "JsonInput" ) {
    $params = [Hashtable]@{}
    ( $jsonParams | convertfrom-json ).psobject.properties | ForEach-Object {
        $params[$_.Name] = $_.Value
    }
}


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false


#-----------------------------------------------
# LOG ENVIRONMENT VARIABLES, IF DEBUG
#-----------------------------------------------
<#
If ( $debug -eq $true ) {
    [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process).GetEnumerator() | ForEach-Object {
        Write-Log "$( $_.Name ) = $( $_.Value )"
    }
}
#>

#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

$modulePath = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
    "C:\Program Files\WindowsPowerShell\Modules"
    #C:\Program Files\powershell\7\Modules
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("windir") )\system32\WindowsPowerShell\v1.0\Modules"
)
$Env:PSModulePath = ( $modulePath | Sort-Object -unique ) -join ";"
# Using $env:PSModulePath for only temporary override


#-----------------------------------------------
# ADD SCRIPT PATH, IF NOT PRESENT
#-----------------------------------------------

#$envVariables = [System.Environment]::GetEnvironmentVariables()
$scriptPath = @( [System.Environment]::GetEnvironmentVariable("Path") -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Scripts"
)
$Env:Path = ( $scriptPath | Sort-Object -unique ) -join ";"
# Using $env:Path for only temporary override


#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug -eq $true ) {

    $params = [hashtable]@{
        Password = 'ko'
        Username = 'ko'
        #scriptPath = 'C:\faststats\Scripts\cleverreach'
        settingsFile = '.\settings.json'
        #mode='taggingOnly'
        #Force64bit = "true"
    }

}


################################################
#
# NOTES
#
################################################

<#

bla bla

#>


################################################
#
# SCRIPT ROOT
#
################################################
<#
if ( $debug -eq $true ) {

    if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
        $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    } else {
        $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    }

    $params.scriptPath = $scriptPath

}

# Some local settings
$dir = $params.scriptPath
Set-Location $dir
#>

# Set current location to the settings files directory
$settingsFile = Get-Item $params.settingsFile
Set-Location $settingsFile.DirectoryName


################################################
#
# 64 BIT CHECK
#
################################################

$thisScript = ".\getmessages.ps1"


#-----------------------------------------------
# CHECK IF 64 BIT SHOULD BE ENFORCED
#-----------------------------------------------

# Start this if 64 is needed to enforce when this process is 32 bit and system is able to handle it
If ( $params.Force64bit -eq "true" -and [System.Environment]::Is64BitProcess -eq $false -and [System.Environment]::Is64BitOperatingSystem -eq $true ) {

    $markerGuid = [guid]::NewGuid().toString()

    try {

        # Input parameter must be a string and for json the double quotes need to be escaped        
        $params.Add("markerGuid", $markerGuid)
        $paramInput = ( ConvertTo-Json $params -Compress -Depth 99 ) -replace '"', '"""'

        # This inputs a string into powershell exe at a virtual place "sysnative"
        # It starts a 64bit version of Windows PowerShell and executes itself with the same input, only encoded as escaped json
        $j = . $Env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -InputFormat text -OutputFormat text  -File $thisScript -JsonParams $paramInput

    } catch {
        Exit 1
    }
  
    # Convert the PSCustomObject back to a hashtable
    $markerRow = $j.IndexOf($markerGuid)
    ( convertfrom-json $j[$markerRow+1] ) #.trim()

    Exit 0

}


################################################
#
# SETTINGS
#
################################################


#-----------------------------------------------
# IMPORT MODULE
#-----------------------------------------------

If ($debug -eq $true) {
    Import-Module "AptecoPSFramework" -Verbose
} else {
    Import-Module "AptecoPSFramework"
}


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


#-----------------------------------------------
# SETTINGS
#-----------------------------------------------

# Set the settings
<#
$settings = Get-settings
$settings.logfile = ".\file.log"
Set-Settings -PSCustom $settings
#>
Import-Settings -Path $params.settingsFile


################################################
#
# PROGRAM
#
################################################

# TODO [x] check if we need to make a try catch here -> not needed, if we use a combination like

<#
            $msg = "Temporary count of $( $mssqlResult ) is less than $( $rowsCount ) in the original export. Please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

#>


#-----------------------------------------------
# GET MESSAGES
#-----------------------------------------------


# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    $return = Get-Messages -InputHashtable $params

    # Return the values, if succeeded
    If ( $PsCmdlet.ParameterSetName -eq "JsonInput" ) {
        $params.markerGuid  # Output a guid to find out the separator
        ConvertTo-Json $return -Depth 99 -Compress # output the result as json
    } else {
        $return
    }    

} catch {

    throw $_.Exception
    Exit 1

}




