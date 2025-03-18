Function Install-AptecoPSFramework {

<#

Calling the function without parameters does the whole part

Calling with one of the Flags, just does this part

#>

    [cmdletbinding()]
    param(
        # [Parameter(Mandatory=$false)][Switch]$ScriptsOnly
        #,[Parameter(Mandatory=$false)][Switch]$ModulesOnly
        #,[Parameter(Mandatory=$false)][Switch]$PackagesOnly
    )

    Begin {

        
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
        # LOAD DEPENDENCY VARIABLES
        #-----------------------------------------------

        . $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$( $Script:moduleRoot )/bin/dependencies.ps1")


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "INSTALLATION"

        # Start the log
        Write-Verbose -message $Script:logDivider -Verbose
        Write-Verbose -message $moduleName -Verbose #-Severity INFO


    }

    Process {

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
        # CHECK ELEVATION
        #-----------------------------------------------

        $isElevated = $false
        if ($os -eq "Windows") {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = [Security.Principal.WindowsPrincipal]::new($identity)
            $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
            Write-Verbose -Message "User: $( $identity.Name )" -Verbose
            Write-Verbose -Message "Elevated: $( $isElevated )" -Verbose
        } else {
            Write-Verbose -Message "No user and elevation check due to OS" -Verbose
        }


        #-----------------------------------------------
        # CHECK AND INSTALL SCRIPT DEPENDENCIES
        #-----------------------------------------------

        # Install newer PackageManagement when it is the default at 1.0.0.1
        $currentPM = get-installedmodule | where-object { $_.Name -eq "PackageManagement" }
        If ( $currentPM.Version -eq "1.0.0.1" -or $currentPSGet.Count -eq 0 ) {
            Write-Verbose "PackageManagement is outdated with v$( $currentPSGet.Version ). Please update now." -Verbose
        }

        # Install newer PowerShellGet version when it is the default at 1.0.0.1
        $currentPSGet = get-installedmodule | where-object { $_.Name -eq "PowerShellGet" }
        If ( $currentPSGet.Version -eq "1.0.0.1" -or $currentPSGet.Count -eq 0 ) {
            Write-Verbose "PowerShellGet is outdated with v$( $currentPSGet.Version ). Please update now." -Verbose
        }

        # Check if Install-Dependenies is present
        If ( @( Get-InstalledScript | Where-Object { $_.Name -eq "Install-Dependencies" } ).Count -lt 1 ) {
            Write-Verbose -Message "Missing dependency, executing: 'Install-Script Install-Dependencies'" -Verbose
            #throw "Missing dependency, execute: 'Install-Script Install-Dependencies'"
            Install-Script Install-Dependencies -Force
        }


        #-----------------------------------------------
        # INSTALL/UPDATE VCREDIST
        #-----------------------------------------------

        # Needed for duckdb

        If ( $os -eq "Windows" ) {

            Write-Verbose -Message "Checking vcredist" -Verbose

            $vcredistInstalled = $False
            $pref = $ErrorActionPreference
            Try {

                $ErrorActionPreference = "stop"
                $vcReg = Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
                If ( $vcReg.Installed -gt 0 ) {

                    $vcredistInstalled = $True
                    Write-Verbose -Message "  Version: $( $vcReg.Version )" -Verbose
                    Write-Verbose -Message "  Major: $( $vcReg.Major )" -Verbose
                    Write-Verbose -Message "  Minor: $( $vcReg.Minor )" -Verbose
                    Write-Verbose -Message "  Build: $( $vcReg.Build )" -Verbose

                }

            } Catch [System.Management.Automation.PSArgumentException] {                
                Write-Warning "vcredist x64 not found" -Verbose
            } Catch [System.Management.Automation.ItemNotFoundException] {               
                Write-Warning "vcredist not found" -Verbose
            } Finally {
                $ErrorActionPreference = $pref
            }

            If ($vcredistInstalled -eq $false ) {

                Write-Warning -Message "Do you want to install vcredist? This is needed for DuckDB, but not to run this module in general." #-Severity WARNING
                $vcredistChoice = Request-Choice -title "Install vcredist?" -message "Do you want to install the newest x64 vcredist?" -choices @("Yes", "No")

                If ( $vcredistChoice -eq 1 ) {

                    Write-Verbose -Message "Installing vcredist... This will need a few minutes" -Verbose

                    # Set the paths1
                    $vcredistPermalink = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
                    $vcredistTargetFile = Join-Path -Path ( [System.Environment]::GetEnvironmentVariable("TMP")) -ChildPath "vc_redist.x64.exe"

                    # Download file - iwr is a bit slow, but works on all operating system
                    #Invoke-WebRequest -UseBasicParsing -Uri $vcredistPermalink -Method Get -OutFile $vcredistTargetFile 

                    # Downlading with Bits as this package is windows only
                    Start-BitsTransfer -Destination $vcredistTargetFile -Source $vcredistPermalink

                    # Install/Update file quietly
                    Start-Process -FilePath $vcredistTargetFile -ArgumentList "/install /q /norestart" -Verb RunAs -Wait

                    Write-Verbose -Message "vcredist installed" -Verbose

                } else {

                    Write-Verbose -Message "Not installing vcredist" -Verbose                

                }

            }

        }

        #-----------------------------------------------
        # CHECK AND INSTALL DEPENDENCIES
        #-----------------------------------------------

        # Check if Install-Dependenies is present
        # If ( @( Get-InstalledScript | Where-Object { $_.Name -eq "Install-Dependencies" } ).Count -lt 1 ) {
        #     throw "Missing dependency, execute: 'Install-Script Install-Dependencies'"
        #     Install-Script Install-Dependencies, Import-Dependencies
        # }

        # Load dependencies as variables
        . ( Join-Path -Path $Script:moduleRoot -ChildPath "/bin/dependencies.ps1" )

        # Call the script to install dependencies
        Write-Verbose "Trying to install/update scripts: $( ( $psScripts -join ", " ) )" -Verbose
        Write-Verbose "Trying to install/update modules: $( ( $psModules -join ", " ) )" -Verbose


        $dependencyParams = [Hashtable]@{
            "Script" = $psScripts
            "Module" = $psModules
            "LocalPackage" = $psLocalPackages
            "GlobalPackage" = $psGlobalPackages
            "ExcludeDependencies" = $True
        }

        If ( $isElevated -eq $False ) {
            $dependencyParams.Add("InstallScriptAndModuleForCurrentUser", $true)
        }

        If ($vcredistInstalled -eq $False ) {
           $dependencyParams.LocalPackage = $psLocalPackages | Where-Object { $_ -notlike 'DuckDB*' -and $_.Name -notlike 'DuckDB*' }
        }

        Write-Verbose "Trying to install/update local packages: $( ( $dependencyParams.LocalPackage -join ", " ) )" -Verbose
        Write-Verbose "Trying to install/update global packages: $( $psGlobalPackages )" -Verbose

        Install-Dependencies @dependencyParams 


        #-----------------------------------------------
        # GIVE SOME HELPFUL OUTPUT
        #-----------------------------------------------

        #If ( $PackagesOnly -eq $false -and $ScriptsOnly -eq $false -and $ModulesOnly -eq $false) {

            # TODO replace the integration parameters

            #try {

        Write-Verbose "This script is copying the boilerplate (needed for installation ) to your current directory." -Verbose
        Write-Warning "This is only needed for the first installation, but recommended after every update. You can also copy the files manually."

        Copy-Item -Path "$( $Script:moduleRoot )\boilerplate\*" -Destination "." -Confirm

        $currentPath = ( resolve-path -Path "." ).Path
        Write-Verbose "Please have a look at your PeopleStage channels and create a new email channel:" -Verbose
        Write-Verbose "  GENERAL" -Verbose
        Write-Verbose "    Broadcaster: PowerShell" -Verbose
        Write-Verbose "    Username: dummy" -Verbose
        Write-Verbose "    Password: dummy" -Verbose
        Write-Verbose "    Email Variable: Please choose your email variable" -Verbose
        Write-Verbose "    Email Variable Description Override: email" -Verbose
        Write-Verbose "  PARAMETER" -Verbose
        Write-Verbose "    URL: https://rest.cleverreach.com/v3/" -Verbose
        Write-Verbose "    GetMessagesScript: $( $currentPath )\getmessages.ps1" -Verbose
        Write-Verbose "    GetListsScript: $( $currentPath )\getmessagelists.ps1" -Verbose
        Write-Verbose "    UploadScript: $( $currentPath )\upload.ps1" -Verbose
        Write-Verbose "    BroadcastScript: $( $currentPath )\broadcast.ps1" -Verbose
        Write-Verbose "    PreviewMessageScript: $( $currentPath )\preview.ps1" -Verbose
        Write-Verbose "    TestScript: $( $currentPath )\test.ps1" -Verbose
        Write-Verbose "    SendTestEmailScript: $( $currentPath )\testsend.ps1" -Verbose
        Write-Verbose "    IntegrationParameters: settingsFile=D:\Scripts\CleverReach\PSCleverReachModule\settings.json;mode=taggingOnly" -Verbose
        Write-Verbose "    Encoding: UTF8" -Verbose
        Write-Verbose "  OUTPUT SETTINGS" -Verbose
        Write-Verbose "    Append To List: false" -Verbose
        Write-Verbose "    Number of retries: 1" -Verbose
        Write-Verbose "    Response File Key Type: Email with Broadcast Id" -Verbose
        Write-Verbose "    Message Content Type: Broadcaster Template" -Verbose
        Write-Verbose "    Retrieve Existing List Names: true" -Verbose
        Write-Verbose "  FILE SETTINGS" -Verbose
        Write-Verbose "    Encoding: UTF-8" -Verbose
        Write-Verbose "  ADDITIONAL VARIABLES" -Verbose
        Write-Verbose "    Add all variables that you would like to always upload" -Verbose
        Write-Verbose "Please consider to ask Apteco to look at your settings when you have done your first setup" -Verbose



            # } catch {
            #     Write-Verbose -Message "Cannot copy boilerplate!" -Severity WARNING
            #     $success = $false
            # }

            # TODO Add hints on how to create the channel in PeopleStage


            <#
            Write-Verbose "Please create the function [Custom].[vModelElementLatest] on the PeopleStage Database by executing this command"

            $sql = Get-Content -Path "$( $moduleRoot )\sql\99_create_vModelElementLatest.sql" -Encoding UTF8 -raw
            # $sqlReplacement = [Hashtable]@{
            #     "#CAMPAIGN#"=$campaignID
            # }
            # $sql = Replace-Tokens -InputString $sql -Replacements $sqlReplacement
            #$customersSql | Set-Content ".\$( $Script:processId ).sql" -Encoding UTF8

            Write-Verbose -Message $sql -Verbose
            #>

        #}


    }

    End {

        #-----------------------------------------------
        # FINISH
        #-----------------------------------------------

        #If ( $success -eq $true ) {
            Write-Verbose -Message "All good. Installation finished!" #-Severity INFO
        #} else {
        #    Write-Error -Message "There was a problem. Please check the output in this window and retry again." #-Severity ERROR
        #}

    }
}

