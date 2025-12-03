function Add-PluginFolder {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [String]$Folder

    )


    process {

        #$return = $false

        # Check if this needs to be declared first
        If ( $null -eq $Script:pluginFolders ) {
            $Script:pluginFolders = [System.Collections.ArrayList]::new()
        }

        # Resolve the path to an absolute path
        #Write-Host "$( $Folder )"
        
        # Resolve the path (even if it does not exist)
        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Folder) #Resolve-Path -Path $Folder

        # Test it
        If ( ( Test-Path -Path $resolvedPath ) -eq $True ) {

            # Add this folder
            [void]$Script:pluginFolders.add($resolvedPath.Path)

            # Register all plugins automatically
            $plugins = Register-Plugins

        } else {

            Write-Error -Message "There is a problem with '$( $resolvedPath )'"
            throw "There is a problem with '$( $resolvedPath )'"

        }

    }

}