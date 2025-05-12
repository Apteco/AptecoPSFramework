function Import-Plugin {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Guid
        ,[Parameter(Mandatory=$false)][string]$ProcessId = ""               # The process id can also be set via this call
    )

    begin {

    }

    process {


        #$success = $false


        #-----------------------------------------------
        # CHECK THE PLUGIN
        #-----------------------------------------------

        # Pick the plugin
        $plugin = @(, ($Script:plugins | Where-Object { $_.guid -eq $Guid }))

        # Check the plugin
        If ( $plugin.count -eq 0 ) {
            Write-Error "Plugin couldn't be found. Please check your guid"
            throw "Plugin couldn't be found. Please check your guid"
            Exit 1
        } elseif ( $plugin.count -gt 1 ) {
            Write-Error "There are more than 1 plugins with the guid, please check your guids!"
            throw "There are more than 1 plugins with the guid, please check your guids!"
            Exit 1
        }


        #-----------------------------------------------
        # LOAD ADDITIONAL PLUGIN SETTINGS
        #-----------------------------------------------

        # Load the plugin settings file
        $pluginSettingsFile = Join-Path -Path $plugin.path -ChildPath "/settings/defaultsettings.ps1"
        Try {
            $pluginSettings = [PSCustomObject]( . $pluginSettingsFile )
        } Catch {
            Write-Error -Message "Failed to import default settings $( $pluginSettingsFile )"
        }
        #$Script:debug = $Script:settings
        # Add more settings from plugin, e.g. if there are new properties due to an update
        #$Script:debug = $Script:settings
        #$scriptSettings = $Script:settings.psobject.copy()
        #$extendedSettings = Add-PropertyRecurse -source $pluginSettings -toExtend $scriptSettings
        $extendedSettings = Join-PSCustomObject -Left $pluginSettings -Right $Script:settings -AddPropertiesFromRight -MergePSCustomObjects -MergeHashtables #-MergeArrays

        # Now harmonise them if there are the same attributes with different values
        #$joinedSettings = Join-Objects -source $extendedSettings -extend $pluginSettings

        #Write-Verbose ( convertto-json $script:settings ) -Verbose

        # Put it back into the variable
        $Script:settings = $extendedSettings
        #$Script:debug = $pluginSettings
        $Script:pluginPath = $plugin.path


        #-----------------------------------------------
        # OVERWRITE META DATA
        #-----------------------------------------------

        # TODO maybe this is not always needed

        If ( $Script:settings.plugin.guid -eq "" ) {

            $Script:settings.plugin."guid" = $plugin.guid
            $Script:settings.plugin."name" = $plugin.name
            $Script:settings.plugin."version" = $plugin.version
            $Script:settings.plugin."lastUpdate" = $plugin.lastUpdate

        }


        #-----------------------------------------------
        # CREATE DYNAMIC MODULE FOR THIS PLUGIN AND PUBLISH IT GLOBALLY
        #-----------------------------------------------

        <#

        This creates a complety dynamic created module which has some default functions that should always be available,
        but can also be extended by custom functions for specific integrations. This dynamic module can be shown via
        Get-Module

        #>

        $pluginParam = [PSCustomObject]@{
            "plugin" = $plugin
            "settings" = $Script:settings
            "variables" = [PSCustomObject]@{
                "moduleRoot" = $Script:moduleRoot
                "logDivider" = $Script:logDivider
                "debugMode" = $Script:debugMode
                "timestamp" = $Script:timestamp
                "execPath" = $Script:execPath
                "processId" = $Script:processId
            }
        }

        # Override process id if delivered through parameters
        If ( $ProcessId -ne "" ) {
            $pluginParam.variables.processId = $ProcessId
        }

        New-Module -Name "$( $plugin.Name )" -ArgumentList $pluginParam -ScriptBlock {

            # argument input object
            param(
                [PSCustomObject]$InputPlugin
            )

            #Write-Verbose ( $Input | ConvertTo-Json ) -Verbose

            #-----------------------------------------------
            # CHECK
            #-----------------------------------------------

            # TODO is the extension of the module path needed here, too? The parent module changes the $Env variable => NO, that works!
            # TODO is the change of the service protocol (TLS) needed here, too? The parent module changes [System.Net.ServicePointManager]::SecurityProtocol


            #-----------------------------------------------
            # CREATE VARIABLES FROM PARENT MODULE
            #-----------------------------------------------

            $InputPlugin.variables.PSObject.Properties | ForEach-Object {
                New-Variable -Name $_.Name -Value $_.Value -Scope Script -Force
            }

            $plugin = $InputPlugin.plugin


            #-----------------------------------------------
            # DOT SOURCE PRIVATE PARENT AND PLUGIN SCRIPTS
            #-----------------------------------------------

            #$Plugins  = @( Get-ChildItem -Path "$( $PSScriptRoot )/plugins/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PrivateParent = @( Get-ChildItem -Path "$( $moduleRoot )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PrivatePlugin = @( Get-ChildItem -Path "$( $plugin.path )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PublicPlugin = @( Get-ChildItem -Path "$( $plugin.path )/public/*.ps1" -Recurse -ErrorAction SilentlyContinue )

            # dot source the files
            @( $PrivateParent + $PrivatePlugin + $PublicPlugin ) | ForEach-Object {
                $import = $_
                #Write-Host "Load $( $import.fullname )"
                Try {
                    . $import.fullname
                } Catch {
                    Write-Error -Message "Failed to import function $( $import.fullname ): $( $_ )"
                }
            }


            #-----------------------------------------------
            # DEFINE MORE VARIABLES
            #-----------------------------------------------

            New-Variable -Name settings -Value $InputPlugin.settings -Scope Script -Force       # Path of the calling script
            New-Variable -Name pluginRoot -Value $plugin.path -Scope Script -Force              # Path of the calling script
            New-Variable -Name pluginDebug -Value $null -Scope Script -Force                    # Debug variable for the scripts
            New-Variable -Name variableCache -Value $null -Scope Script -Force                  # Caching variable for shared plugin information like apiusage

            #Write-verbose ( Convertto-json $Script:settings -dept 99 ) -Verbose
            $Script:variableCache = [Hashtable]@{}


            #-----------------------------------------------
            # START LOG
            #-----------------------------------------------

            Set-ProcessId -Id $InputPlugin.variables.processId

            Write-Log -message $Script:logDivider
            Write-Log -Message "Using the process id $( $InputPlugin.variables.processId )"


            #-----------------------------------------------
            # LOAD PARENT AND PLUGIN DEPENDENCIES
            #-----------------------------------------------

            # TODO only using modules yet, but also look at packages and scripts

            # Load dependencies
            . ( Join-Path -Path $moduleRoot -ChildPath "/bin/dependencies.ps1" )

            #try {
            #    @( $psModules + $plugin.dependencies.psModules ) | ForEach-Object {
            #        $mod = $_
            #        Import-Module -Name $mod -ErrorAction Stop
            #    }
            #} catch {
            #    Write-Error "Error loading dependencies. Please execute 'Install-AptecoPSFramework' or 'Install-Plugin' now"
            #    Exit 0
            #}


            # Load packages from current local libfolder
            # If you delete packages manually, this can increase performance but there could be some functionality missing
            #Write-Verbose "Hello test" -verbose
            #Write-Log "Hello $( $psLocalPackages.Count )"
            #Write-Verbose " $( ( $settings | convertto-json -Depth 99 ) ) " -Verbose
            #Get-Variable | % {
            #    Write-Verbose "Var $( $_.Name ) - $( $_.Value )" -VErbose
            #}
            #Write-Verbose "Hello $( ( ) )" -verbose #$InputPlugin.settings.loadlocalLibFolder | convertto-json -Compress

            #Write-Log "Func $((get-command PackageManagement\Get-Package).Parameters.Keys -join ", " ))"

            $dependencyParams = [Hashtable]@{
               "Module" = @( $psModules + $plugin.dependencies.psModules )
            }

            $p = get-command "get-package"
            write-log "Using this PackageManagement to load packages: $( $p.DLL )"
            #Write-log $p.Version

            If ( $psLocalPackages.Count -gt 0  -and $settings.loadlocalLibFolder -eq $true ) {
                Write-Verbose "Loading local packages" #-verbose
                try {

                    # Work out the local lib folder

                    #$localLibFolder = Resolve-Path -Path $Script:settings.localLibFolder
                    $localLibFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settings.localLibFolder)

                    #Write-Log "$( ( Get-Package -Name "PackageManagement" ).Version )"

                    If ( Test-Path -Path $localLibFolder ) {
                        Write-Verbose "Loading from $( $localLibFolder )" #-verbose

                        #$localLibFolderItem = get-item $localLibFolder.Path

                        # Remember current location and change folder
                        #$currentLocation = Get-Location
                        #Set-Location $localLibFolderItem.Parent.FullName

                        # Import the dependencies
                        Write-Log "Loading lib folder from: '$( $localLibFolder )'"
                        $dependencyParams.Add("LoadWholePackageFolder", $true)
                        $dependencyParams.Add("LocalPackageFolder", $localLibFolder)
                        $dependencyParams.Add("SuppressWarnings", $true)

                         #$localLibFolderItem.fullname

                        # Go back, if needed
                        #Set-Location -Path $currentLocation.Path

                    } else {

                        Write-Verbose "You have no local lib folder to load. Not necessary a problem. Proceeding..." #-verbose #-Severity Warning

                    }


                } catch {
                    Write-Log $_.exception -Severity WARNING
                    Write-Host "There was a problem importing packages in the local lib folder, but proceeding..."# -Severity Warning

                }

            }

            # Load modules and packages
            try {
                #@( $psModules + $plugin.dependencies.psModules ) | ForEach-Object {
                #    $mod = $_
                #    Import-Module -Name $mod -ErrorAction Stop
                #}
                Import-Dependencies @dependencyParams
            } catch {
                Write-Warning "Error loading module, script and package dependencies. Please execute 'Install-AptecoPSFramework' or 'Install-Plugin' now" -Verbose
            }

            # Load assemblies
            $psAssemblies | ForEach-Object {
                $ass = $_
                Add-Type -AssemblyName $ass
            }


            #-----------------------------------------------
            # EXPORT PUBLIC FUNCTIONS
            #-----------------------------------------------

            Export-ModuleMember -Function $PublicPlugin.Basename #-verbose  #+ "Set-Logfile"

            # TODO Check if we need to set the process identifier, because it is already a public function
            # Get-ProcessId
            # Set-ProcessIdentifier


        } | Import-Module -Global

        #$class = $plugin.class #[DemoPlugin]::new($plugin.path)
        #$class.load()
        #$Script:plugin = $class




        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        Write-Log "Plugin successfully loaded" -Severity VERBOSE

        #$success = $true

        #$success


    }

    end {

    }
}