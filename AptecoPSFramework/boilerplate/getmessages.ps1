
################################################
#
# INPUT
#
################################################

Param(
    [hashtable] $params
)


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false


#-----------------------------------------------
# LOG ENVIRONMENT VARIABLES, IF DEBUG
#-----------------------------------------------

If ( $debug -eq $true ) {
    [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process).GetEnumerator() | ForEach-Object {
        Write-Log "$( $_.Name ) = $( $_.Value )"
    }
}


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
    $return

} catch {

    throw $_.Exception
    Exit 1

}




