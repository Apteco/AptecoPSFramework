Param(
     $SettingsFile
    #,$TokenSettings
)


#-----------------------------------------------
# IMPORT MODULE AND SETTINGS
#-----------------------------------------------

Import-Module AptecoPSFramework, WriteLog
Import-Settings -Path $SettingsFile

$s = Get-Settings
Set-Logfile -Path $s.logfile

Write-Log "----------------------------------------------------"
Write-Log "CHECK TOKEN" -Severity INFO


#-----------------------------------------------
# EXCHANGE TOKEN
#-----------------------------------------------

# Exchange file
Save-NewToken
