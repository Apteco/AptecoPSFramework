################################################
#
# INPUT
#
################################################

Param(
    [hashtable] $params
)


################################################
#
# NOTES
#
################################################


<#

This script is used for when you want everything to be executed with PowerShell Core

This one gets called and uses the original scripts through pwsh

#>

################################################
#
# SETTINGS
#
################################################

# temporary files to handle objects
$inputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$( $Env:Temp )/$( [System.Guid]::NewGuid().toString() )_input.tmp")
$outputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$( $Env:Temp )/$( [System.Guid]::NewGuid().toString() )_output.tmp")

$verb = "TestSend"


################################################
#
# PROGRAM
#
################################################


#-----------------------------------------------
# FIND OUT CURRENT DIRECTORY
#-----------------------------------------------

$settingsFile = Get-Item -Path $params.settingsFile


#-----------------------------------------------
# CHECK IF PWSH IS INSTALLED
#-----------------------------------------------

$isPwshInstalled = $false
try {
    if ( (pwsh { 1+1 }) -eq 2 ) {
        $isPwshInstalled = $true
    }
} catch {
    #"not there"
}


#-----------------------------------------------
# START PWSH PROCESS
#-----------------------------------------------

If ( $isPwshInstalled -eq $true ) {

    # Save the hashtable to a json file
    $htInput | ConvertTo-Json -Compress -Depth 99 | Set-Content -Path $inputFile -Encoding UTF8

    # Call pwsh with the test file and some parameters and wait for finish
    # TODO [ ] Add error handling and maybe timeout?
    $coreWrapper = Join-Path -Path $settingsFile.DirectoryName -ChildPath "core_wrapper.ps1"
    pwsh -File $coreWrapper -Verb $verb -InputFile $inputFile -OutputFile $outputFile

    # Read return values
    $j = Get-Content -Path $outputFile -Raw -Encoding UTF8 | ConvertFrom-Json

    # Convert the PSCustomObject back to a hashtable
    $htOutput = [Hashtable]@{}
    $j.psobject.properties | ForEach-Object {
        $htOutput[$_.Name] = $_.Value
    }

    # Remove the temporary json files
    Remove-Item -Path $InputFile
    Remove-Item -Path $OutputFile

} else {

    "Sorry, please install pwsh"

}