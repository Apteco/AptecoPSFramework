﻿
################################################
#
# INPUT
#
################################################

[CmdletBinding()]
Param(

    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
    [String]$SettingsFile = ""

)


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false
If ( $PSBoundParameters["Debug"].IsPresent -eq $true ) {
    $debug = $true
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
# PATH
#
################################################


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


################################################
#
# CHECKS
#
################################################

#-----------------------------------------------
# CHECK INPUT
#-----------------------------------------------

If ( $PsCmdlet.ParameterSetName -eq "JobIdInput" ) {
    If ( $SettingsFile -eq "" ) {
        throw "Please define a settings file"
    } else {
        $settingsfileLocation = $SettingsFile
    }
} else {
    $settingsfileLocation = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($params.settingsFile)
}

#-----------------------------------------------
# CHANGE PATH
#-----------------------------------------------

# Set current location to the settings files directory
$settingsFileItem = Get-Item $settingsfileLocation
Set-Location $settingsFileItem.DirectoryName


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
# SET SETTINGS
#-----------------------------------------------

# Set the settings
If ( $useJob -eq $true -and $ProcessId -ne "") {
    Import-Settings -Path $settingsfileLocation -ProcessId $ProcessId
} else {
    Import-Settings -Path $settingsfileLocation
}

# Get all settings
$s = Get-Settings


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


################################################
#
# PROGRAM
#
################################################


#-----------------------------------------------
# GET MESSAGES
#-----------------------------------------------

# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    $return = Get-Response

    # Return the values, if succeeded
    $return

} catch {

    throw $_
    Exit 1

}




