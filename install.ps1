
#-----------------------------------------------
# NOTES
#-----------------------------------------------

<#

# To get this script going, make sure to allow the exeuction of scripts with

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser


# To get the download of the script going, you maybe need TLS12 support with

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

#>


#-----------------------------------------------
# GENERAL
#-----------------------------------------------

$isError = $false
$scriptSourceUrl = "https://raw.githubusercontent.com/Apteco/AptecoPSFramework/main/install.ps1"
$tempScriptFile = Join-Path $Env:Temp -ChildPath "install_aptecopsframework.ps1"


#-----------------------------------------------
# LOAD CURRENT PATH
#-----------------------------------------------
<#
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
} else {
    $scriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}
#>
$scriptPath = ( Resolve-Path -Path "." ).Path

Write-Verbose "Current Path: $( $scriptPath )" -Verbose


#-----------------------------------------------
# ADD MODULE PATH, IF NOT PRESENT
#-----------------------------------------------

$modulePaths = @( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) + @(
    "C:\Program Files\WindowsPowerShell\Modules"
    #C:\Program Files\powershell\7\Modules
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Modules"
    "$( [System.Environment]::GetEnvironmentVariable("windir") )\system32\WindowsPowerShell\v1.0\Modules"
)
$Env:PSModulePath = ( $modulePaths | Sort-Object -unique ) -join ";"
# Using $env:PSModulePath for only temporary override

Write-Verbose "[OK] Adding module path" -Verbose


#-----------------------------------------------
# ADD SCRIPT PATH, IF NOT PRESENT
#-----------------------------------------------

#$envVariables = [System.Environment]::GetEnvironmentVariables()
$scriptPaths = @( [System.Environment]::GetEnvironmentVariable("Path") -split ";" ) + @(
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\WindowsPowerShell\Scripts"
    "$( [System.Environment]::GetEnvironmentVariable("USERPROFILE") )\Documents\WindowsPowerShell\Scripts"
)
$Env:Path = ( $scriptPaths | Sort-Object -unique ) -join ";"
# Using $env:Path for only temporary override

Write-Verbose "[OK] Adding script path" -Verbose


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
# CHECKING ELEVATION
#-----------------------------------------------

# Check elevation
$isElevated = $false
if ( $os -eq "Windows" ) {

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Verbose -Message "User: $( $identity.Name )" -Verbose
    Write-Verbose -Message "Elevated: $( $isElevated )" -Verbose

} else {

    Write-Warning -Message "[FAIL] No user and elevation check due to OS. Leaving here!"
    Exit 1

}

# TODO think about giving the choice to not install with elevated rights, but on own risk
If ( $isElevated -eq $false ) {

    # Open PowerShell with elevated rights
    Write-Warning -Message "For the initial setup it would be better to use elevated rights."
    Write-Warning -Message "This is now opening a new powershell window with elevated rights."
    Write-Warning -Message "Please repeat ""iwr https:// -useb | iex"" there"

    try {

        #Start-Process powershell -Verb RunAs

        # Download the script, unblock it, create arguments with current directory and open elevated PowerShell with that folder and execute the script again
        Invoke-WebRequest -Uri $scriptSourceUrl -UseBasicParsing -Method GET -OutFile $tempScriptFile
        Unblock-File -Path $tempScriptFile # This does not seem to be needed, but doesn't hurt
        $CommandLineArgumentList = "-NoExit", "-Command", "Set-Location ""$( $scriptPath )"";. ""$( $tempScriptFile )"""
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $CommandLineArgumentList

    } catch {

        throw "[FAIL] Failed to start PowerShell with elevated rights"
        Exit 1

    }

} else {

    Write-Verbose "[OK] Using elevation" -Verbose

}

# Then proceed


#-----------------------------------------------
# CHECKING EXECUTION POLICY
#-----------------------------------------------

# Check your executionpolicy: https:/go.microsoft.com/fwlink/?LinkID=135170
#$execPolicyUser = Get-ExecutionPolicy -Scope CurrentUser
#$execPolicyMachine = Get-ExecutionPolicy -Scope LocalMachine

Write-Verbose "Current exeucution policies:" -Verbose
Get-ExecutionPolicy -List | ForEach-Object {   
    Write-Verbose "  $( $_.Scope ): $( $_.ExecutionPolicy )" -Verbose
}
<#
try {

    Write-Verbose "Setting the current exeuction policy to 'RemoteSigned'"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

} catch {

    $isError = $true

    # Setting the exeuction policy back
    Set-ExecutionPolicy -ExecutionPolicy $execPolicyUser -Scope CurrentUser

    throw "There is a problem setting the execution policy"
    Exit 1

} finally {

}
#>


#-----------------------------------------------
# UPDATE YOUR POWERSHELLGET
#-----------------------------------------------

try {

    # Make sure to have PowerShellGet >= 1.6.0
    #Get-InstalledModule -Name PowerShellGet -MinimumVersion 1.6.0
    $psg = @( Get-InstalledModule | Where-Object { $_.Name -eq "PowerShellGet" -and $_.Version -gt "1.6.0" } )

    If ( $psg.Count -eq 0 ) {
        Install-Module -Name PowerShellGet -AllowClobber -Force
        $psg = @( Get-InstalledModule | Where-Object { $_.Name -eq "PowerShellGet" -and $_.Version -gt "1.6.0" } )
        Write-Verbose "[OK] PowerShellGet $( $psg.Version ) >= 1.6.0 available" -Verbose
    } else {
        Write-Verbose "[OK] PowerShellGet $( $psg.Version ) >= 1.6.0 available" -Verbose
    }

} catch {

    $isError = $true

    # Setting the exeuction policy back
    #Set-ExecutionPolicy -ExecutionPolicy $execPolicyUser -Scope CurrentUser

    throw "[FAIL] There is a problem with the installation of PowerShellGet"

} finally {

}


#-----------------------------------------------
# INSTALL VCREDIST
#-----------------------------------------------

If ( $os -eq "Windows" ) {

    # Set the paths
    $vcredistPermalink = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    $vcredistTargetFile = Join-Path -Path ( [System.Environment]::GetEnvironmentVariable("TMP")) -ChildPath "vc_redist.x64.exe"

    # Download file - iwr is a bit slow, but works on all operating system
    #Invoke-WebRequest -UseBasicParsing -Uri $vcredistPermalink -Method Get -OutFile $vcredistTargetFile
    
    # Downlading with Bits as this package is windows only
    Start-BitsTransfer -Destination $vcredistTargetFile -Source $vcredistPermalink

    # Install file quietly
    Start-Process -FilePath $vcredistTargetFile -ArgumentList "/install /q /norestart" -Verb RunAs -Wait
    
}


#-----------------------------------------------
# INSTALL BASE SCRIPTS AND MODULES
#-----------------------------------------------

try {

    install-module writelog
    Write-Verbose "[OK] Installed module WriteLog" -Verbose

    install-script install-dependencies, import-dependencies
    Write-Verbose "[OK] Installed scripts 'Install-Dependencies' and 'Import-Dependencies'" -Verbose

    Install-Dependencies -module aptecopsframework
    Write-Verbose "[OK] Installed module AptecoPSFramework and dependencies" -Verbose

} catch {

    $isError = $true

    # Setting the exeuction policy back
    #Set-ExecutionPolicy -ExecutionPolicy $execPolicyUser -Scope CurrentUser

    throw "[FAIL] There is a problem with the installation of base dependencies"

} finally {

}


#-----------------------------------------------
# IMPORT THE MODULE AND INSTALL MORE DEPENDENCIES
#-----------------------------------------------

# No try/catch here as the first import of aptecopsmodule will cause an error because of missing dependencies
$targetPathDefault = Resolve-Path -Path "." # $resolvedLogPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PSCustom."logfile")
$targetPath = Read-Host -Prompt "Please enter the path where you want to put the scripts and settings to. Default is '[$( $targetPathDefault )]'"

# If prompt is empty, just use default path
if ( $targetPath -eq "" -or $null -eq $targetPath) {
    $targetPath = $targetPathDefault
}

# Test the path and proceed
If ( Test-Path -Path $targetPath -IsValid ) {
    Write-Verbose "The target path is valid" -verbose
    If ( Test-Path -Path $targetPath ) {

        Set-Location -Path $targetPath
        Write-Verbose "[OK] Using path: '$( $targetPath )'" -Verbose

        Import-Module AptecoPSFramework
        Install-AptecoPSFramework -verbose
        Write-Verbose "[OK] Loaded and installed AptecoPSFramework" -Verbose

    } else {
        throw "[FAIL] The target path '$( $targetPath )' is not existing"
    }
} else {
    throw " [FAIL] The target path '$( $targetPath )' is not valid"
}

Write-Verbose "[OK] All done here, you are good to go" -Verbose


#-----------------------------------------------
# CREATE A FIRST DEMO CHANNEL
#-----------------------------------------------

Write-Verbose "Creating a first Demo Channel to use" -Verbose

# Re-Import the module
Import-Module -Name "AptecoPSFramework" -Force
Write-Verbose "[OK] Re-Imported module AptecoPSFramework" -Verbose

# Default file
$settingsFileDefault = Join-Path -Path $scriptPath -ChildPath "/demo.yaml"

# Ask for another path
$settingsFile = Read-Host -Prompt "Where do you want the demo settings file to be saved? Just press Enter for this default '[$( $settingsFileDefault )]'"

# If prompt is empty, just use default path
if ( $settingsFile -eq "" -or $null -eq $settingsFile) {
    $settingsFile = $settingsFileDefault
}

# Check if filename is valid
if(Test-Path -LiteralPath $settingsFile -IsValid ) {
    Write-Verbose "[OK] SettingsFile '$( $settingsFile )' is valid" -Verbose
} else {
    throw "[FAIL] SettingsFile '$( $settingsFile )' contains invalid characters"
}

# Set the plugin and export settings
$plugin = Get-Plugins | Where-Object { $_.name -eq "Demo" }
Write-Verbose "[OK] Loaded Demo plugin info with guid '$( $plugin.guid )'" -Verbose

Import-Plugin -Guid $plugin.guid
Write-Verbose "[OK] Imported Demo plugin" -Verbose

$s = Get-Settings
Write-Verbose "[OK] Got the settings of plugin in variable `$s" -Verbose

# You could change settings now! Or edit them in the yaml file.
$s.logfile = ".\file.log"
Write-Verbose "[OK] Changing logfile path in settings to: $( $s.logfile )" -Verbose

Set-Settings -PSCustom $s
Write-Verbose "[OK] Settings set!" -Verbose

Export-Settings -Path $settingsFile
Write-Verbose "[OK] Exported settings to $( $settingsFile )" -Verbose

Write-Verbose "Next time you simply could just enter" -Verbose
Write-Verbose "Import-Settings ""$( $settingsFile )""" -Verbose
Write-Verbose "And for example get a messagelist with" -Verbose
Write-Verbose "Get-Messages" -Verbose


#-----------------------------------------------
# REMOVE TEMP FILE, IF EXISTS
#-----------------------------------------------

If ( (Test-Path -Path $tempScriptFile ) -eq $true ) {
    Remove-Item -Path $tempScriptFile -Force
    Write-Verbose "[OK] Removed temporary script file" -Verbose
}
