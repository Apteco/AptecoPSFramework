
#-----------------------------------------------
# NOTES
#-----------------------------------------------

<#

Inspired by Tutorial of RamblingCookieMonster in
http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
and
https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psm1

#>


#-----------------------------------------------
# ENUMS
#-----------------------------------------------




#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

$modulePath = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
    #C:\Program Files\PowerShell\Modules
    #c:\program files\powershell\7\Modules
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
# LOAD DEFAULT SETTINGS
#-----------------------------------------------

$defaultsettingsFile = Join-Path -Path $PSScriptRoot -ChildPath "/settings/defaultsettings.ps1"
Try {
    $Script:defaultSettings = [PSCustomObject]( . $defaultsettingsFile )
} Catch {
    Write-Error -Message "Failed to import default settings $( $defaultsettingsFile )"
}
$Script:settings = $Script:defaultSettings


#-----------------------------------------------
# LOAD NETWORK SETTINGS
#-----------------------------------------------

# Allow only newer security protocols
# hints: https://www.frankysweb.de/powershell-es-konnte-kein-geschuetzter-ssltls-kanal-erstellt-werden/
if ( $Script:settings.changeTLS ) {
    # $AllProtocols = @(
    #     [System.Net.SecurityProtocolType]::Tls12
    #     #[System.Net.SecurityProtocolType]::Tls13,
    #     #,[System.Net.SecurityProtocolType]::Ssl3
    # )
    [System.Net.ServicePointManager]::SecurityProtocol = @( $Script:settings.allowedProtocols )

    # Microsoft is using this setting in examples
    #[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

}

# TODO look for newer version of this network stuff


#-----------------------------------------------
# LOAD PUBLIC AND PRIVATE FUNCTIONS
#-----------------------------------------------

#$Plugins  = @( Get-ChildItem -Path "$( $PSScriptRoot )/plugins/*.ps1" -Recurse -ErrorAction SilentlyContinue )
$Public  = @( Get-ChildItem -Path "$( $PSScriptRoot )/public/*.ps1" -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$( $PSScriptRoot )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )


# dot source the files
@( $Public + $Private ) | ForEach-Object {
    $import = $_
    Write-Verbose "Load $( $import.fullname )"
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
    }
}


#-----------------------------------------------
# SET SOME VARIABLES ONLY VISIBLE TO MODULE AND FUNCTIONS
#-----------------------------------------------

# Define the variables
#New-Variable -Name execPath -Value $null -Scope Script -Force       # Path of the calling script
New-Variable -Name processId -Value $null -Scope Script -Force      # GUID process ID to identify log messages that belong to one process
New-Variable -Name timestamp -Value $null -Scope Script -Force      # Start time of this module
New-Variable -Name debugMode -Value $null -Scope Script -Force      # Debug mode switch
New-Variable -Name logDivider -Value $null -Scope Script -Force     # String of dashes to use in logs
New-Variable -Name moduleRoot -Value $null -Scope Script -Force     # Current location root of this module
New-Variable -Name debug -Value $null -Scope Script -Force          # Debug variable where you can put in any variables to read after executing the script, good for debugging
New-Variable -Name pluginFolders -Value $null -Scope Script -Force  # Folders array for loading plugins
New-Variable -Name plugins -Value $null -Scope Script -Force        # Plugins collection for all registered plugins
New-Variable -Name pluginPath -Value $null -Scope Script -Force     # The path of the chosen plugin
New-Variable -Name plugin -value $null -Scope Script -Force         # The plugin pscustomobject

# Set the variables now
$Script:timestamp = [datetime]::Now
$Script:debugMode = $false
$Script:logDivider = "----------------------------------------------------" # String used to show a new part of the log
$Script:moduleRoot = $PSScriptRoot.ToString()

# instantiate plugin with dummy values
# TODO remove this dummy values
$Script:plugin = [PSCustomObject]@{
    #"abc" = "def"
}


#-----------------------------------------------
# IMPORT MODULES
#-----------------------------------------------

# Load dependencies
. ( Join-Path -Path $PSScriptRoot.ToString() -ChildPath "/bin/dependencies.ps1" )

try {
    $psModules | ForEach-Object {
        $mod = $_
        Import-Module -Name $mod -ErrorAction Stop
    }
} catch {
    Write-Error "Error loading dependencies. Please execute 'Install-AptecoPSFramework' now"
    Exit 0
}


# Load packages from current local libfolder
If ( $psLocalPackages.Count -gt 0 ) {
    Import-Dependencies -LoadWholePackageFolder
}


# Load assemblies
$psAssemblies | ForEach-Object {
    $ass = $_
    Add-Type -AssemblyName $_
}


#-----------------------------------------------
# REGISTER AVAILABLE PLUGINS
#-----------------------------------------------

# Add default plugins folder
Add-PluginFolder -Folder ( join-path -Path $PSScriptRoot.ToString() -ChildPath "plugins" )
#$plugins = Register-Plugins


#-----------------------------------------------
# LOAD SECURITY SETTINGS
#-----------------------------------------------

If ("" -ne $Script:settings.keyfile) {
    If ( Test-Path -Path $Script:settings.keyfile -eq $true ) {
        Import-Keyfile -Path $Script:settings.keyfile
    } else {
        Write-Error "Path to keyfile is not valid. Please check your settings json file!"
    }
}


#-----------------------------------------------
# MAKE PUBLIC FUNCTIONS PUBLIC
#-----------------------------------------------

Export-ModuleMember -Function $Public.Basename #-verbose  #+ "Set-Logfile"
#Export-ModuleMember -Function $Private.Basename #-verbose  #+ "Set-Logfile"


#-----------------------------------------------
# SET THE LOGGING
#-----------------------------------------------

# Set a new process id first, but this can be overridden later
Set-ProcessId -Id ( [guid]::NewGuid().toString() )

# the path for the log file will be set with loading the settings