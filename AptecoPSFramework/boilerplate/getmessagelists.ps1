
################################################
#
# INPUT
#
################################################

[CmdletBinding(DefaultParameterSetName='HashtableInput')]
Param(

    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='HashtableInput')]
    [hashtable]$params = [Hashtable]@{}

    #,[Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='JsonInput')]
    #[String]$JsonParams = ""

    ,[Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='JobIdInput')]
    [String]$JobId = ""

    ,[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='JobIdInput')]
    [String]$SettingsFile = ""

    ,[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='JobIdInput')]
    [String]$ProcessId = ""

    ,[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='HashtableInput')]
    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='JobIdInput')]
    [String]$DebugMode = "false"        # This is a string, because when sent trough multiple processes, only text can be transferred instead of native objects

)


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false

If ( $DebugMode -eq "true" ) {
    $debug = $true
}
# TODO make an example lie
# . ./upload.ps -JobId 123 -DebugMode


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
        Password = 'ko'
        Username = 'ko'
        
        # Integration parameters
        #Force64bit = "true"
        #ForceCore = "true"
        #ForcePython = "true"
        #UseJob = "true"
        settingsFile = '.\inx.yaml'
    }

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


#-----------------------------------------------
# CHECK INPUT
#-----------------------------------------------

If ( $PsCmdlet.ParameterSetName -eq "JobIdInput" ) {
    If ( $SettingsFile -eq "" ) {
        throw "Please define a settings file"
    } else {
        $settingsfileLocation = $SettingsFile
        $useJob = $true
    }
} else {
    $settingsfileLocation = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($params.settingsFile)
}


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


################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# CHANGE PATH
#-----------------------------------------------

# Set current location to the settings files directory
$settingsFileItem = Get-Item $settingsfileLocation
Set-Location $settingsFileItem.DirectoryName


#-----------------------------------------------
# IMPORT MODULE
#-----------------------------------------------

If ($debug -eq $true) {
    Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework" -Verbose
} else {
    Import-Module "C:\Users\Florian\Documents\GitHub\AptecoPSFramework\AptecoPSFramework"
}


#-----------------------------------------------
# SET DEBUG MODE
#-----------------------------------------------

Set-DebugMode -DebugMode $debug


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
# ADD JOB
#-----------------------------------------------

If ( $params.UseJob -eq "true" -or $useJob -eq $true -and $PsCmdlet.ParameterSetName -eq "HashtableInput") {

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

}


#-----------------------------------------------
# FIND OUT ABOUT PS CORE
#-----------------------------------------------

$calc = . $s.psCoreExePath { 1+1 }
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


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# CALL MESSAGELISTS
#-----------------------------------------------

$thisScript = ".\getmessagelists.ps1"


# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    Switch ( $mode ) {

        "function" {

            If ( $useJob -eq $true ) {
                Get-Groups -JobId $jobId
            } else {
                $return = Get-Groups -InputHashtable $params
            }

            break
        }


        "PSWin64" {

            # This inputs a string into powershell exe at a virtual place "sysnative"
            $j = . $Env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -InputFormat text -OutputFormat text -File $thisScript -JobId $jobId -SettingsFile $settingsfileLocation -ProcessId ( Get-ProcessIdentifier ) -DebugMode:$debug.toString() -InformationAction "Continue" 

            break

        }


        "PSCore" {

            # Check if ps core is installed
            If ( $isPsCoreInstalled -eq $false ) {
                throw "PowerShell Core does not seem to be installed or found"
            }
            
            # This inputs a string into powershell exe at a virtual place "sysnative"
            # It starts a 64bit version of Windows PowerShell and executes itself with the same input, only encoded as escaped json
            $j = . $s.psCoreExePath -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -InputFormat text -OutputFormat text -File $thisScript -JobId $jobId -SettingsFile $settingsfileLocation -ProcessId ( Get-ProcessIdentifier ) -DebugMode:$debug.toString() -InformationAction "Continue" 

            break
        }


        "Python" {

            <#

            assuming you have a python file like add.py and this content

            ```Python
            import sys

            # This program adds two numbers
            num1 = float(sys.argv[1])
            num2 = 6.3

            # Add two numbers
            sum = num1 + num2

            # Display the sum
            print('The sum of {0} and {1} is {2}'.format(num1, num2, sum))
            ```

            #>

            # Then it can be called like this
            . $s.pythonPath add.py "5.5"

            break
        }

    }

    # return
    If ( $LASTEXITCODE -ne 0 ) {
        $j
    } else {
        If ( $useJob -eq $true ) {
            $jobReturn = Get-JobLog -JobId $jobId -ConvertOutput
            $return = $jobReturn.output
        }
        $return
    }


} catch {

    throw $_
    Exit 1

} finally {

    # Close the connection to joblog
    If ( $useJob -eq $true ) {
        Close-JobLogDatabase
    }

}
