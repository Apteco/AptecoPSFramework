
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
    $jsonInput = $jsonParams -replace '\"', '"'
    $params = [Hashtable]@{}
    ( $jsonInput | convertfrom-json ).psobject.properties | ForEach-Object {
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

    try {

        #Write-Verbose "$( $params | ConvertTo-Json -Compress -Depth 99 )" -Verbose

        # Input parameter must be a string and for json the double quotes need to be escaped
        $paramInput = ( ConvertTo-Json $params -Compress -Depth 99 ) -replace '"', '\"'

        # This inputs a string into powershell exe at a virtual place "sysnative"
        # It starts a 64bit version of Windows PowerShell and executes itself with the same input, only encoded as escaped json
        $j = . $Env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -InputFormat text -OutputFormat xml -File $thisScript -JsonParams $paramInput

    } catch {
        Exit 1
    }

    # Convert the PSCustomObject back to a hashtable
    #$htOutput = [Hashtable]@{}
    #( $j | convertfrom-json ).psobject.properties | ForEach-Object {
    #    $htOutput[$_.Name] = $_.Value
    #}

    # Return the hashtable
    #$htOutput
    $j.return

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

try {

    Import-Module "AptecoPSFramework" -Verbose

} catch {

    # ADD MODULE PATH, IF NOT PRESENT
    $modulePath = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
        "C:\Program Files\WindowsPowerShell\Modules"
        #C:\Program Files\powershell\7\Modules
        "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
        "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
        "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
        "$( [System.Environment]::GetEnvironmentVariable("windir") )\system32\WindowsPowerShell\v1.0\Modules"
    )
    $Env:PSModulePath = ( $modulePath | Sort-Object -unique ) -join ";"

    # Try again
    Import-Module "AptecoPSFramework" -Verbose

}


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


#-----------------------------------------------
# SETTINGS
#-----------------------------------------------

# Set the settings
Import-Settings -Path $params.settingsFile


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
    $return = Get-Messages -InputHashtable $params

    # Return the values, if succeeded
    If ( $PsCmdlet.ParameterSetName -eq "JsonInput" ) {
        #return ( $return | ConvertTo-Json -Depth 99 -Compress )
        [Hashtable]@{
            "return" = $return
        }
    } else {
        $return
    }


} catch {

    throw $_.Exception
    Exit 1

}




