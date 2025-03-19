
################################################
#
# SCRIPT ROOT
#
################################################

# if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
#     $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# } else {
#     $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
# }

# Set-Location -Path $scriptPath

#-----------------------------------------------
# CHECKING PS AND OS
#-----------------------------------------------

Write-Verbose "Check PowerShell and Operating system" -Verbose

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

Write-Verbose -Message "Using OS: $( $os )" -Verbose


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
# MODULES
#
################################################

Import-Module "AptecoPSFramework", "EncryptCredential"


################################################
#
# SETTINGS
#
################################################

#-----------------------------------------------
# ADD MORE PLUGINS
#-----------------------------------------------

#Add-PluginFolder "D:\Scripts\CleverReach\Plugins"


#-----------------------------------------------
# CHOOSE A PLUGIN
#-----------------------------------------------

$plugin = @(, (get-plugins | Select-Object guid, name, version, lastUpdate, stage, category, type, path | Out-GridView -PassThru ))

If ($plugin.count -gt 1) {
    Write-Host "Sorry, you have chosen more than 1 plugin"
    exit 1
} elseif ( $plugin.count -eq 0 ) {
    Write-Host "Sorry, you have chosen less than 1 plugin"
    exit 1
}


#-----------------------------------------------
# LOAD THE PLUGIN
#-----------------------------------------------

Import-Plugin -guid $plugin.guid


#-----------------------------------------------
# LOAD THE SETTINGS (GLOBAL + PLUGIN)
#-----------------------------------------------

$settings = Get-settings


################################################
#
# CHANGE PARAMETERS
#
################################################

# logfile
$settings.logfile = ".\file.log"


# Override settings
#$settings."pageSize" = 5

# TODO need to remove this later to connecting the api through an APP


#-----------------------------------------------
# SETTINGS FOR 'GENERATE'
#-----------------------------------------------

# $settings.token.tokenUsage = "generate"
# $settings.login.accesstoken = $token
# $settings.login.refreshtoken = $token


#-----------------------------------------------
# SETTINGS FOR 'CONSUME'
#-----------------------------------------------

# $settings.token.tokenUsage = "consume"

# # Define as absolute path
# #$tokenfile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\cr.token") # Or resolve the relative path into absolute
# $tokenfile = "D:\Scripts\CleverReach\check-token214112\cr.token"
# $settings.token.tokenFilePath = $tokenfile


################################################
#
# SET AND EXPORT SETTINGS
#
################################################

Set-Settings -PSCustom $settings
Export-Settings -Path ".\settings.yaml"
