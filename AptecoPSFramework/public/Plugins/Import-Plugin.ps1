function Import-Plugin {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$Guid
        ,[Parameter(Mandatory=$false)][string]$ProcessId = ""               # The process id can also be set via this call
    )

    begin {

    }

    process {


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

        # Add more settings from plugin, e.g. if there are new properties due to an update
        $extendedSettings = Merge-PSCustomObject -Left $pluginSettings -Right $Script:settings -AddPropertiesFromRight -MergePSCustomObjects -MergeHashtables #-MergeArrays

        # Put it back into the variable
        $Script:settings = $extendedSettings
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

        Write-Verbose "Starting to load the temporary module"

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
                Write-Verbose "Creating variable $( $_.Name ) with value $( $_.Value )"
                New-Variable -Name $_.Name -Value $_.Value -Scope Script -Force
            }

            $plugin = $InputPlugin.plugin


            #-----------------------------------------------
            # DOT SOURCE PRIVATE PARENT AND PLUGIN SCRIPTS
            #-----------------------------------------------

            $PrivateParent = @( Get-ChildItem -Path "$( $moduleRoot )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PrivatePlugin = @( Get-ChildItem -Path "$( $plugin.path )/private/*.ps1" -Recurse -ErrorAction SilentlyContinue )
            $PublicPlugin = @( Get-ChildItem -Path "$( $plugin.path )/public/*.ps1" -Recurse -ErrorAction SilentlyContinue )

            # dot source the files
            @( $PrivateParent + $PrivatePlugin + $PublicPlugin ) | ForEach-Object {
                $import = $_
                #Write-Host "Load $( $import.fullname )"
                Try {
                    Write-Verbose "Loading $( $import.fullname )"
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

            $Script:variableCache = [Hashtable]@{}


            #-----------------------------------------------
            # START LOG
            #-----------------------------------------------

            Set-Logfile -Path $Script:settings.logfile
            Set-ProcessId -Id $InputPlugin.variables.processId

            Write-Log -message $Script:logDivider
            Write-Log -Message "Using the process id $( $InputPlugin.variables.processId )"


            #-----------------------------------------------
            # LOAD PARENT AND PLUGIN DEPENDENCIES
            #-----------------------------------------------

            # Load dependencies
            . ( Join-Path -Path $moduleRoot -ChildPath "/bin/dependencies.ps1" )

            $loadedModules = Get-Module
            $dependencyParams = [Hashtable]@{
               "Module" = @( $psModules + $plugin.dependencies.psModules ) | Where-Object { $_ -notin $loadedModules.Name }
            }


            If ( $psLocalPackages.Count -gt 0  -and $settings.loadlocalLibFolder -eq $true ) {
                Write-Verbose "Loading local packages" #-verbose
                try {

                    # Work out the local lib folder
                    $localLibFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settings.localLibFolder)
                    If ( Test-Path -Path $localLibFolder ) {

                        If ( $Env:SkipLocalLibFolder -ne $true ) {

                            Write-Verbose "Loading from $( $localLibFolder )" #-verbose

                            If ( $Env:SkipDuckDB -eq $true ) {

                                Write-Log "Skipping DuckDB package load as per environment variable 'SkipDuckDB'" #-verbose
                                $psEnv = Get-PSEnvironment -LocalPackageFolder $localLibFolder -SkipBackgroundCheck
                                $packagesToLoad = [Array]@( $psEnv.InstalledLocalPackages | where-object { $_.Name -notlike "DuckDB.*" } )
                                If ( $packagesToLoad.Count -eq 0 ) {
                                    Write-Log "No packages to load after skipping DuckDB" #-verbose
                                } else {
                                    $dependencyParams.Add("LocalPackages", $packagesToLoad)
                                }

                            } else {

                                # Import the dependencies
                                Write-Log "Loading whole lib folder from: '$( $localLibFolder )'"
                                $dependencyParams.Add("LoadWholePackageFolder", $true)
                                $dependencyParams.Add("LocalPackageFolder", $localLibFolder)
                                $dependencyParams.Add("SuppressWarnings", $true)
                            
                            }

                        } else {
                            Write-Verbose "Skipping loading local lib folder as per environment variable 'SkipLocalLibFolder'" #-verbose
                        }


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
                Import-Dependency @dependencyParams
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

        } | Import-Module -Global


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        Set-ProcessId -Id $Script:processId
        Write-Log "Plugin successfully loaded" -Severity VERBOSE


    }

    end {

    }
}