
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
# DEFAULT VALUES
#-----------------------------------------------

$useJob = $false
$enforce64Bit  = $false
$enforceCore = $false
$enforcePython = $false
$isPsCoreInstalled = $false

If ( $PsCmdlet.ParameterSetName -eq "JobIdInput" -and $settingsfileLocation -ne "" ) {
    $useJob = $true
}


################################################
#
# SETTINGS
#
################################################


#-----------------------------------------------
# CHECK THE MODE THAT SHOULD BE USED
#-----------------------------------------------

# Start this if 64 is needed to enforce when this process is 32 bit and system is able to handle it
If ( $params.Force64bit -eq "true" -and [System.Environment]::Is64BitProcess -eq $false -and [System.Environment]::Is64BitOperatingSystem -eq $true ) {
    $enforce64Bit = $true
    $useJob = $true
}

# When you want to use PSCore with 32bit, please change that path in the settings file
If ( $params.ForceCore -eq "true" ) {
    $enforceCore = $true
    $useJob = $true
}

If ( $params.ForcePython -eq "true" ) {
    $enforcePython = $true
    $useJob = $true
}


#-----------------------------------------------
# IMPORT MODULE
#-----------------------------------------------

If ($debug -eq $true) {
    Import-Module "C:\FastStats\Scripts\github\AptecoPSFramework" -Verbose
} else {
    Import-Module "C:\FastStats\Scripts\github\AptecoPSFramework"
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


#-----------------------------------------------
# ADD JOB
#-----------------------------------------------

If ( $params.UseJob -eq "true" -or $useJob -eq $true) {

    If ( $PsCmdlet.ParameterSetName -eq "HashtableInput" ) {

        # Create a new job
        $jobId = Add-JobLog
        $jobParams = [Hashtable]@{
            "JobId" = $JobId
            #"Plugin" = $script:settings.plugin.guid
            "InputParam" = $params
            #"Status" = "Starting"
            "DebugMode" = $debug
        }
        Update-JobLog @jobParams

    } else {

        $job = Get-JobLog -JobId $JobId -ConvertInput

        If ( $job.debug -eq "1" ) {
            $debug = $True
            Set-DebugMode -DebugMode $debug
        }

    }

}


#-----------------------------------------------
# FIND OUT ABOUT PS CORE
#-----------------------------------------------
try {
    $calc = . $s.psCoreExePath { 1+1 }
} catch {
    # just a test, nothing to do
}
if ( $calc -eq 2 ) {
    $isPsCoreInstalled = $true
}


#-----------------------------------------------
# FIND OUT THE MODE
#-----------------------------------------------

$mode = "function"
If ( $enforce64Bit -eq $true ) {
    $mode = "PSWin64"
} elseif ( $enforceCore -eq $true ) {
    $mode = "PSCore"
} elseif ( $enforcePython -eq $true ) {
    $mode = "Python"
}