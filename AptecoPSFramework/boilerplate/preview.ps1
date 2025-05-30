﻿
################################################
#
# INPUT
#
################################################

[CmdletBinding(DefaultParameterSetName='HashtableInput')]
Param(

    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='HashtableInput')]
    [hashtable]$params = [Hashtable]@{}

    #,[Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='JsonInput')]
    #[String]$JsonParams = ""

    ,[Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='JobIdInput')]
    [String]$JobId = ""

    ,[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='JobIdInput')]
    [String]$SettingsFile = ""

    ,[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='JobIdInput')]
    [String]$ProcessId = ""

)


#-----------------------------------------------
# DEBUG SWITCH
#-----------------------------------------------

$debug = $false
If ( $PSBoundParameters["Debug"].IsPresent -eq $true ) {
    $debug = $true
}


#-----------------------------------------------
# INPUT PARAMETERS, IF DEBUG IS TRUE
#-----------------------------------------------

if ( $debug -eq $true ) {

    $params = [hashtable]@{

        # Automatic parameters
        Password = 'def'
        #scriptPath = 'D:\Scripts\CleverReach\PSCleverReachModule'
        MessageName = '8088752 ~ Demo_Fundraising'
        TestRecipient = '{"Email":"reply@apteco.de","Sms":null,"Personalisation":{"Kunden ID":"","email":"florian.von.bracht@apteco.de","Vorname":"","Communication Key":"93d02a55-9dda-4a68-ae5b-e8423d36fc20"}}'
        Username = 'abc'
        mode = 'prepare'
        ListName = ''

        # Integration parameters
        #Force64bit = "true"
        #ForceCore = "true"
        #ForcePython = "true"
        #UseJob = "true"
        settingsFile = '.\inx.yaml'

    }

}


################################################
#
# CHECKS
#
################################################

#-----------------------------------------------
# CHECK INPUT
#-----------------------------------------------

If ( $PsCmdlet.ParameterSetName -eq "JobIdInput" ) {
    If ( $SettingsFile -eq "" ) {
        throw "Please define a settings file"
    } else {
        $settingsfileLocation = $SettingsFile
    }
} else {
    $settingsfileLocation = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($params.settingsFile)
}

#-----------------------------------------------
# CHANGE PATH
#-----------------------------------------------

# Set current location to the settings files directory
$settingsFileItem = Get-Item $settingsfileLocation
Set-Location $settingsFileItem.DirectoryName


################################################
#
# LOAD COMMON SETTINGS AND CHECKS
#
################################################

. "./common.ps1"


################################################
#
# PROGRAM
#
################################################

#-----------------------------------------------
# CALL NEXT STEP
#-----------------------------------------------

$thisScript = ".\preview.ps1"

# Added try/catch again because of extras.xml wrapper
try {

    # Do the upload
    Switch ( $mode ) {

        "function" {

            If ( $useJob -eq $true ) {
                Show-Preview -JobId $jobId -Debug:$debug
            } else {
                $return = Show-Preview -InputHashtable $params -Debug:$debug
            }

            break
        }


        "PSWin64" {

            $j = . $Env:SystemRoot\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -InputFormat text -OutputFormat text -File $thisScript -JobId $jobId -SettingsFile $settingsfileLocation -ProcessId ( Get-ProcessIdentifier ) -InformationAction "Continue"

            break

        }


        "PSCore" {

            # Check if ps core is installed
            If ( $isPsCoreInstalled -eq $false ) {
                throw "PowerShell Core does not seem to be installed or found"
            }

            # This inputs a string into powershell exe at a virtual place "sysnative"
            # It starts a 64bit version of Windows PowerShell and executes itself with the same input, only encoded as escaped json
            $j = . $s.psCoreExePath -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -InputFormat text -OutputFormat text -File $thisScript -JobId $jobId -SettingsFile $settingsfileLocation -ProcessId ( Get-ProcessIdentifier ) -InformationAction "Continue"

            break
        }


        "Python" {

            <#

            assuming you have a python file like add.py and this content

            ```Python
            import sys

            # This program adds two numbers
            num1 = float(sys.argv[1])
            num2 = 6.3

            # Add two numbers
            sum = num1 + num2

            # Display the sum
            print('The sum of {0} and {1} is {2}'.format(num1, num2, sum))
            ```

            #>

            # Then it can be called like this
            . $s.pythonPath add.py "5.5"

            break
        }

    }

    # return
    If ( $LASTEXITCODE -gt 0 ) {
        $j
    } else {
        If ( $useJob -eq $true ) {
            $jobReturn = Get-JobLog -JobId $jobId -ConvertOutput
            $return = $jobReturn.output
        }
        $return
    }


} catch {

    throw $_
    Exit 1

} finally {

    # Close the connection to joblog
    If ( $useJob -eq $true ) {
        Close-JobLogDatabase
    }

}