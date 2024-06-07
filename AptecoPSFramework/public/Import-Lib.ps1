
Function Import-Lib {
    <#

    ...

    #>
    [cmdletbinding()]
    param(

    )

    Process {

        # Load packages from current local libfolder
        # If you delete packages manually, this can increase performance but there could be some functionality missing

        try {

            # Work out the local lib folder

            #$localLibFolder = Resolve-Path -Path $Script:settings.localLibFolder
            $localLibFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Script:settings.localLibFolder)

            If ( Test-Path -Path $localLibFolder ) {

                #$localLibFolderItem = get-item $localLibFolder.Path

                # Remember current location and change folder
                #$currentLocation = Get-Location
                #Set-Location $localLibFolderItem.Parent.FullName

                # Import the dependencies
                Import-Dependencies -LoadWholePackageFolder -LocalPackageFolder $localLibFolder #$localLibFolderItem.name

                # Go back, if needed
                #Set-Location -Path $currentLocation.Path

            } else {

                Write-Warning "You have no local lib folder to load. Not necessary a problem. Proceeding..."

            }


        } catch {

            Write-Warning "There was a problem importing packages in the local lib folder, but proceeding..."

        }

    }




}
