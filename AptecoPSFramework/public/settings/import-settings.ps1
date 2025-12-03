<#

Inspired by

https://gist.github.com/ksumrall/3b7010a9fbc9c5cb19e9dc8b9ee32fb1

#>

Function Import-Settings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][String]$Path = "./settings.yaml"
        ,[Parameter(Mandatory=$false)][String]$ProcessId = ""               # The process id can also be set via this call
    )

    Process {

        # Try to resolve the path
        $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        Write-Verbose "Try to import the settings file at '$( $absolutePath )'"

        # Work out the extension - the file does not need to exist for that
        $pathExtension = [System.IO.Path]::GetExtension($Path)

        try {

            If ( ( Test-Path -Path $absolutePath -IsValid ) -eq $true ) {

                If (( Test-Path -Path $absolutePath ) -eq $true) {

                    # Load the new settings file
                    try {

                        # Now save the settings file
                        Switch ( $pathExtension ) {

                            { $PSItem -in @( ".yml", ".yaml" ) } {
                                $settings = [PSCustomObject]( Get-Content -Path $absolutePath -Encoding utf8 -Raw | ConvertFrom-Yaml -Ordered )
                            }

                            default {
                                $settings = Get-Content -Path $absolutePath -Encoding utf8 -Raw | ConvertFrom-Json
                            }

                        }

                    } catch {
                        Write-Error "There is a problem loading the settings file"
                        throw $_
                    }

                    # Register all plugins
                    try {
                        $settings.pluginFolders | ForEach-Object {
                            $f = $_
                            Add-PluginFolder "$( $f )"
                        }
                    } catch {
                        Write-Error "There is a problem registering plugins"
                        throw $_
                    }

                    # Joining the settings together
                    try {
                        $joinedSettings = Merge-PSCustomObject -Left $Script:defaultSettings -Right $settings -AddPropertiesFromRight -MergePSCustomObjects -MergeHashtables #-MergeArrays
                    } catch {
                        Write-Error -Message "Settings cannot be joined"
                        throw $_
                    }

                    # Set the settings into the module (modules defaultsettings + imported settings)
                    try {
                        Set-Settings -PSCustom $joinedSettings
                    } catch {
                        Write-Error -Message "Settings cannot be loaded"
                        throw $_
                    }

                    # TODO [x] load the plugins from the settings file, if present
                    try {
                        If ( $ProcessId -ne "" ) {
                            Import-Plugin -guid $settings.plugin.guid -ProcessId $ProcessId
                        } else {
                            Import-Plugin -guid $settings.plugin.guid
                        }
                    } catch {
                        Write-Error -Message "Plugin cannot be imported"
                        throw $_
                    }

                } else {

                    throw "The settings file '$( $absolutePath )' cannot be found"

                }

            } else {

                #Write-Error -Message "The settings file '$( $absolutePath )' cannot be loaded."
                throw "The settings file '$( $absolutePath )' path is not valid"

            }

        } catch {

            #Write-Error -Message "The path '$( $absolutePath )' is invalid."
            throw $_ #"The path '$( $absolutePath )' is invalid."

        }

        # Return
        #Get-Settings

    }

}