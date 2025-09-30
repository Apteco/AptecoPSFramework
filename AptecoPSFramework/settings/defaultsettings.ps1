# TODO please be aware, that the join-object function does not support $null yet

[PSCustomObject]@{

    # General
    "logfile" = "./logfile.log"                             # default logfile
    "useOnlyOneLogfile" = $false                          # if true, then only one logfile will be used e.g. for import-dependency and install-dependencies and psoauth
    "encoding" = "utf8"
    "nameConcatChar" = " ~ "
    "currentDate" = [datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss")

    # Chosen plugin
    "plugin" = [PSCustomObject]@{                           # This will be filled with the plugin that you need to choose
        "guid" = ""                                         # The guid of the plugin that will be used with this settings file
        "name" = ""
        "version" = "0.0.1"
        "lastUpdate" = "2023-06-15"
    }
    "pluginFolders" = [Array]@()                            # Default folders that should been loaded to look for plugins

    # Network and Security
    "changeTLS" = $true                                     # change TLS automatically to a newer version
    "allowedProtocols" = @(,"Tls12")                        # Protocols that should be used like Tls12, Tls13, SSL3
    "keyfile" = ""                                          # Define a path in here, if you use another keyfile for https://www.powershellgallery.com/packages/EncryptCredential/0.0.2

    # PowerShell/Python
    "powershellExePath" =  "$( $Env:SystemRoot )\sysnative\WindowsPowerShell\v1.0\powershell.exe"
                                                            # Default powershell to use. Could be changed to something like pwsh.exe for the scheduled task of refreshing token and response gathering
                                                            # To make sure to use the 64 bit version, change this to an absolute path like
                                                            # This inputs a string into powershell exe at a virtual place "sysnative"

    "psCoreExePath" = "$( (Get-PwshPath) )"
                                                            # The absolute path of PSCore, if you want to use PSCore x86 (32 bit), then change the path to something like
                                                            # "$( [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)") )\PowerShell\7\pwsh.exe"
                                                            # or
                                                            # C:\Program Files (x86)\PowerShell\7\pwsh.exe

    "pythonPath" = "$( (Get-PythonPath) )"

    # Local lib folder
    "loadlocalLibFolder" = $true
    "localLibFolder" = "./lib"

    # DuckDB
    "defaultDuckDBConnection" = "Data Source=:memory:;"     # Default DuckDB connection -> In-Memory connection, could also be a file
    "queriesBeforeUploadWithDuckDB" = [Array]@()
    #"upload" = [PSCustomObject]@{
    #    "queriesBeforeUploadWithDuckDB" = [Array]@()
    #}

    # LogJob database (sqlite file via DuckDB will directly made, not connected to defaultDuckDBConnection)
    "joblogDB" = "./logjob.sqlite"

}