
################################################
#
# PATH
#
################################################


#-----------------------------------------------
# CHECKING PS AND OS
#-----------------------------------------------

Write-Verbose "Check PowerShell and Operating system"

# Check if this is Pwsh Core
$isCore = ($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')

Write-Verbose -Message "Using PowerShell version $( $PSVersionTable.PSVersion.ToString() ) and $( $PSVersionTable.PSEdition ) edition" -Verbose

# Check the operating system, if Core
if ($isCore -eq $true) {
    $os = If ( $IsWindows -eq $true ) {
        "Windows"
    } elseif ( $IsLinux -eq $true ) {
        "Linux"
    } elseif ( $IsMacOS -eq $true ) {
        "MacOS"
    } else {
        throw "Unknown operating system"
    }
} else {
    # [System.Environment]::OSVersion.VersionString()
    # [System.Environment]::Is64BitOperatingSystem
    $os = "Windows"
}

Write-Verbose -Message "Using OS: $( $os )"


#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

$modulePath = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("windir") )\system32\WindowsPowerShell\v1.0\Modules"
)

# Add the 64bit path, if present. In 32bit the ProgramFiles variables only returns the x86 path
If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\WindowsPowerShell\Modules"
}

# Add pwsh core path
If ( $isCore -eq $true ) {
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\powershell\7\Modules"
    }
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\powershell\7\Modules"
    $modulePath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\powershell\7\Modules"
}

# Add all paths
# Using $env:PSModulePath for only temporary override
$Env:PSModulePath = @( $modulePath | Sort-Object -unique ) -join ";"


#-----------------------------------------------
# ADD SCRIPT PATH, IF NOT PRESENT
#-----------------------------------------------

#$envVariables = [System.Environment]::GetEnvironmentVariables()
$scriptPath = @( [System.Environment]::GetEnvironmentVariable("Path") -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Scripts"
)

# Add the 64bit path, if present. In 32bit the ProgramFiles variables only returns the x86 path
If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\WindowsPowerShell\Scripts"
}

# Add pwsh core path
If ( $isCore -eq $true ) {
    If ( [System.Environment]::GetEnvironmentVariables().keys -contains "ProgramW6432" ) {
        $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramW6432") )\powershell\7\Scripts"
    }
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\powershell\7\Scripts"
    $scriptPath += "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\powershell\7\Scripts"
}

# Using $env:Path for only temporary override
$Env:Path = @( $scriptPath | Sort-Object -unique ) -join ";"


################################################
#
# LOG
#
################################################


#-----------------------------------------------
# DEFINE TEMPORARY LOG FILE
#-----------------------------------------------

Import-Module WriteLog
Import-Module ImportDependency

$tmpdir = Get-TemporaryPath
Set-Logfile -Path "$( $tmpdir )\AptecoPSFramework.log"
#[System.Environment]::GetEnvironmentVariables() TEMP/TMP

# Log the params, if existing
Write-Log -message "Input Parameterset: $( $PsCmdlet.ParameterSetName )"
If ( $PsCmdlet.ParameterSetName -eq "HashtableInput" ) {

    Write-Log -message "INPUT:"
    if ( $Params ) {
        $Params.Keys | ForEach-Object {
            $param = $_
            Write-Log -message "    $( $param ) = '$( $Params[$param] )'" -writeToHostToo $false
        }
    }

} else {

    Write-Log "Using JobId: $( $JobId )"

}


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


#-----------------------------------------------
# LOGGING
#-----------------------------------------------

Write-Log -Message "This script: $( $thisScript )"
Write-Log -Message "Using OS: $( $os )"
Write-Log -Message "64bit OS: $( [System.Environment]::Is64BitOperatingSystem  )"
Write-Log -Message "64bit Process: $( [System.Environment]::Is64BitProcess  )"
Write-Log -Message "Using PowerShell version $( $PSVersionTable.PSVersion.ToString() ) and $( $PSVersionTable.PSEdition ) edition" -Verbose
Write-Log -Message "Running as user: $( [System.Security.Principal.WindowsIdentity]::GetCurrent().Name )"
Write-Log -Message "Debug Mode: $( $debug )"


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

Write-Log -Message "Enforce 64bit: $( $enforce64Bit )"
Write-Log -Message "Enforce Job: $( $useJob )"


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

Write-Log "Import settings from file: $( $settingsfileLocation )"

# Set the settings
If ( $useJob -eq $true -and $ProcessId -ne "") {
    Import-Settings -Path $settingsfileLocation -ProcessId $ProcessId
} else {
    Import-Settings -Path $settingsfileLocation
}

# Get all settings
$s = Get-Settings

Write-Log "Use process id: $( Get-ProcessIdentifier ) from now on"


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


#-----------------------------------------------
# ADD JOB
#-----------------------------------------------

If ( $params.UseJob -eq "true" -or $useJob -eq $true) {

    If ( $PsCmdlet.ParameterSetName -eq "HashtableInput" ) {

        Write-Log "Create a new job"

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

        Write-Log "Created a new job with id $( $jobId )"

    } else {

        Write-Log "Using existing job with id $( $JobId )"

        $job = Get-JobLog -JobId $JobId -ConvertInput

        If ( $job.debug -eq "1" ) {
            $debug = $True
            Set-DebugMode -DebugMode $debug
        }

    }

} else {

    Write-Log "No job will be used"

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

Write-Log -Message "Is PSCore installed: $( $isPsCoreInstalled )"


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

Write-Log "Using mode: $( $mode )"