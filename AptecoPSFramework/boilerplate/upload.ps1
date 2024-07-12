
################################################
#
# INPUT
#
################################################

[CmdletBinding(DefaultParameterSetName='HashtableInput')]
Param(

    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='HashtableInput')]
    [hashtable]$params = [Hashtable]@{},

    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='JsonInput')]
    [String]$jsonParams = ""

)

# If this script is called by itself, re-transform the escaped json string input back into a hashtable
If ( $PsCmdlet.ParameterSetName -eq "JsonInput" ) {
    $params = [Hashtable]@{}
    ( $jsonParams.replace("'",'"') | convertfrom-json ).psobject.properties | ForEach-Object {
        Write-verbose "$( $_.Name ) - $( $_.Value )"
        $params[$_.Name] = $_.Value
    }
}


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false


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

if ( $debug -eq $true -and $jsonParams -eq "" ) {
    $params = [hashtable]@{

        # Automatic parameters
        ReplyToEmail = 'reply@apteco.de'
        Password = 'def'
        #scriptPath = 'D:\Scripts\CleverReach\PSCleverReachModule'
        MessageName = ''
        EmailFieldName = 'email'
        SmsFieldName = ''
        Path = 'd:\faststats\Publish\Handel\system\Deliveries\PowerShell_1158984 ~ Demo_Fundraising_20230606-155652_55935023-5af7-49bf-8bd7-2e3c67234cd4.txt'
        TransactionType = 'Replace'
        Username = 'abc'
        ReplyToSMS = ''
        UrnFieldName = 'Kunden ID'
        ListName = '1158984 ~ Demo_Fundraising_20230606-155652'
        CommunicationKeyFieldName = 'Communication Key'

        # Integration parameters
        #Force64bit = "true"
        settingsFile = '.\settings.json'

    }
}

#Write-Log -message "Got a file with these arguments: $( [Environment]::GetCommandLineArgs() )" -writeToHostToo $false


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

$thisScript = ".\upload.ps1"


#-----------------------------------------------
# CHECK IF 64 BIT SHOULD BE ENFORCED
#-----------------------------------------------

# Start this if 64 is needed to enforce when this process is 32 bit and system is able to handle it
If ( $params.Force64bit -eq "true" -and [System.Environment]::Is64BitProcess -eq $false -and [System.Environment]::Is64BitOperatingSystem -eq $true ) {

    $markerGuid = [guid]::NewGuid().toString()

    try {

        # Input parameter must be a string and for json the double quotes need to be escaped
        $params.Add("markerGuid", $markerGuid)
        $paramInput = ( ConvertTo-Json $params -Compress -Depth 99 ).replace('"',"'")

        # This inputs a string into powershell exe at a virtual place "sysnative"
        # It starts a 64bit version of Windows PowerShell and executes itself with the same input, only encoded as escaped json
        $j = . $Env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -InputFormat text -OutputFormat text -File $thisScript -JsonParams $paramInput -InformationAction "Continue"

    } catch {
        Exit 1
    }

    # Check for warnings and errors
    $j | ForEach-Object {
        $jrow = $_
        Switch -Wildcard ( $jrow ) {

            "INFO*" {
                Write-Information -MessageData $jrow -Tags @("Info") -InformationAction Continue
            }

            "WARNING*" {
                Write-Warning -Message $jrow
            }

            "WARNUNG*" {
                Write-Warning -Message $jrow
            }

        }
    }

    # Convert the PSCustomObject back to a hashtable
    $markerRow = $j.IndexOf($markerGuid)
    ( convertfrom-json $j[$markerRow+1].replace("'",'"') ) #.trim()

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
# ADD MORE PLUGINS
#-----------------------------------------------

#Add-PluginFolder "D:\Scripts\CleverReach\Plugins"


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


#-----------------------------------------------
# SET SETTINGS
#-----------------------------------------------

# Set the settings
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

or

            Write-Log -Message "Failed to connect to SQLServer database" -Severity ERROR
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_

#>


#-----------------------------------------------
# CALL UPLOAD
#-----------------------------------------------

# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    $return = Invoke-Upload $params

    # Return the values, if succeeded
    If ( $PsCmdlet.ParameterSetName -eq "JsonInput" ) {
        $params.markerGuid  # Output a guid to find out the separator
        ( ConvertTo-Json $return -Depth 99 -Compress ).replace('"',"'") # output the result as json
    } else {
        $return
    }

} catch {

    throw $_
    Exit 1

}
