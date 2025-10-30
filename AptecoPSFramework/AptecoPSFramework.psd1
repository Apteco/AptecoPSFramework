
@{

# Script module or binary module file associated with this manifest.
RootModule = 'AptecoPSFramework.psm1'

# Version number of this module.
ModuleVersion = '0.4.7'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'ada4a156-dea2-4821-9c8b-e7ef33a7fa46'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2025 Apteco GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Apteco PS Modules - Framework

This module allows Apteco, partners and customers to develop their own integrations.
This framework brings lots of useful features with it like
- Logging + Send information to Orbit UI
- Standardised settings management saved in json files
- Update upward compatibility when there are new features and setting possibilites
- Errorhandling and causing stop of campaigns on problems
- Installation of dependencies
- Developer mode to quickly create own integrations
- Secure encryption of tokens and credentials
- Possibility to develop cmdlets that can be executed directly in PowerShell e.g. to start clean up jobs or download specific data from an integration...
- Easy boilerplate, documentation on GitHub and Demo-Channel to start quickly
- Easy updates via PowerShellGallery
- Easy integration of proxies, custom headers, REST handling
- Using secure oAuth for connected apps like Microsoft Dynamics, Salesforce SalesCloud and CleverReach
- Using DuckDB by default since 0.3.0 to allow easy data transformation
- Much more to follow...

Your help is appreciated. Just contact me.
'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# Using our own dependency module later for more scripts/modules/packages
RequiredModules = @(
    "WriteLog"
    #"PowerShellGet"
    #"SqlServer"
    #"EncryptCredential"
    #"ConvertUnixTimestamp"
)


# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(

    "Add-PluginFolder"
    "Export-Settings"
    "Get-Debug"
    "Get-Plugin"
    "Get-PluginFolders"
    "Get-Plugins"
    "Get-ProcessIdentifier"
    "Get-Settings"
    "Import-Plugin"
    "Import-Settings"
    "Install-AptecoPSFramework"
    "Register-Plugins"
    "Set-DebugMode"
    "Set-ExecutionDirectory"
    #"Set-ProcessIdentifier"
    "Set-Settings"
    "Install-Plugin"

    "Open-DuckDBConnection"
    "Get-DuckDBConnection"
    "Close-DuckDBConnection"
    "Read-DuckDBQueryAsReader"
    "Read-DuckDBQueryAsScalar"
    "Invoke-DuckDBQueryAsNonExecute"
    "Add-DuckDBConnection"
    "Get-DebugMode"
    "Import-Lib"

    "Add-JobLog"
    "Get-JobLog"
    "Update-JobLog"
    "Set-JobLogDatabase"
    "Close-JobLogDatabase"
    #"Clean-JobLogDatabase"

) #'*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @() #'*'

# Variables to export from this module
VariablesToExport = @() #'*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @() #'*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # 'Tags' wurde auf das Modul angewendet und unterstützt die Modulermittlung in Onlinekatalogen.
        Tags = @("PSEdition_Desktop", "Windows", "Apteco")

        # Eine URL zur Lizenz für dieses Modul.
        LicenseUri = 'https://gist.github.com/gitfvb/58930387ee8677b5ccef93ffc115d836'
        # For future use: <license type="expression">MIT</license>

        # Eine URL zur Hauptwebsite für dieses Projekt.
        ProjectUri = 'https://github.com/Apteco/AptecoPSFramework'

        # Eine URL zu einem Symbol, das das Modul darstellt.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # release channel
        #Prerelease = 'alpha6'

        # 'ReleaseNotes' des Moduls
        ReleaseNotes = '
      Feature: Adding integration for Optilyz
0.4.7 Feature CleverReach: Added new function to batch load responses by day in a loop to avoid a too high workload
      Feature: Enhanced the boilerplate to output more information about the current process
      Fix CleverReach: Changed some datatypes to enhance performance of response gathering
      Fix: Join-PSCustomObject and Join-Hashtable were not working properly if you have a filled subobject on the left
          side and an empty subobject on the right side. It just overwrites it with the empty subobject. This is now fixed
          to use the left object
0.4.6 Feature: Removed dependency to install modules globally
      Feature Salesforce: Added new functions to add/remove records without bulk api
      Feature Salesforce: Added new function to upload accounts and personaccounts into CampaignMember object
      Fix: Some confusion with logfiles when importing plugins and settings
0.4.5 Feature: Added new functions for Apteco email
      Fix: Improved the error handling in the http functions when the domain name cannot be resolved
      Fix: Use of $Script:logdivider instead of $logdivider
0.4.4 Feature: Currently only one logfile is used for everything. Now there is a switch in the settings to allow multiple logfiles like for import-dependencies etc.
      Fix: The boilerplate common file had an absolute path instead of the module name for import-module
0.4.3 Fixed temporary module and script path loading
0.4.2 Fix: Added more common module and script paths
      Fix: Handling dependency problems in plugins as warnings rather than errors
0.4.1 Fix: Small bugfix for Install-AptecoPSFramework where the vcredist installation is not checked again after installation
      Fix: Small bugfix for Packagemanagement version check at the start of Install-AptecoPSFramework
0.4.0 Feature: Massive improvements for the Salesforce integration. Have a look at the documentation for more information
      Feature: Added MergeHashtable and MergePSCustomObject as Dependencies for future use in settings
      Feature CleverReach: New function to download all receivers of a list
      Feature: Improved boilerplate files to be runnable with -Debug flag instead of setting that in the script file.
               In that case it uses the params object inside that file
      Feature: Improved Performance for DuckDB reader (e.g. 5 seconds for 150k rows instead of 70 seconds)
      Feature: Improved handling for sniffing csv files with DuckDB (example is in help)
      Feature: Adding FundraisingBox as a new plugin for the Apteco PS Framework allowing to load data through the API
      Feature: Improved the whole exception handling for all parts in the framework, so the messaging should be more clear, if problems occur
      Feature: Changed the way Apteco email builds up arrays, so the performance in loading contactlists should be a little bit better
      Feature: Added SimplySql in the new version 2 to the dependencies
      Feature: Adding a new local database with sqlite/DuckDB to log jobs into a database which will make it much easier to repeat jobs
      Feature: Adding an internal Function Add-HttpQueryPart to add new parts to a URI query
      Feature: Improved Performance for DuckDB reader (e.g. 5 seconds for 150k rows instead of 70 seconds)
      Feature: Improved handling for sniffing csv files with DuckDB (example is in help)
      Fix CleverReach: When having spaces around a column name, it will be trimmed now automatically
      Fix CleverReach: When there are more people in the last upload batch than the uploadsize, then only the first (last) batch was done
      Fix CleverReach: Adding an option to disable keepalives when the connection causes problems
      Fix CleverReach: Added a hint, if a http 403 Forbidden happens, that this could be caused because of too many uploaded contacts regarding the licence
      Fix CleverReach: When requesting contacts per tag, it is now limited to 5000 per page and now sorted by count rather than tag name
      Fix: Improved the error output, when settings are imported
      Fix: Added ConvertStrings as another dependency
      Fix: API Ratelimiting could cause problems when also containing whitespace, this has been fixed
      Fix: Renaming Prepare-MultipartUpload to ConvertTo-MultipartUpload to only use allowed verbs
      Fix: Renaming Prompt-Choice to Request-Choice to only use allowed verbs
      Fix: Settings merging was not working properly when a sub property is an [Ordered] instead of [Hashtable] or [PSCustomObject].
           Also the count of properties was not correct when merging settings. That is all fixed now.
0.3.3 Fix: Setting a default logfile at the start of the module load named "logfile.log"
      Fix: Reflected a new flag for installing dependencies so that DuckDB is not installing all dependent packages of DuckDB.NET
      Fix: Improved the error handling and messaging for loading settings files
      Maintenance: Removed some not needed scripts
0.3.2 Feature: Added code for emarsys specific functions like downloading lists, campaigns, fields and contacts
      Fix: All verbose outputs for plugins do now work with the -verbose flag
      Fix: Remove the boolean output when adding a pluginfolder
0.3.1 Fix: Throwing full exceptions via iwr and irm to catch more details of exception in the plugin
0.3.0 Feature: Adding DuckDB as dependencies to the framework by default so the campaign file can be read (and written) through DuckDB query
               more effectively than through a .NET streamreader or streamwriter when you want to transform the file
               If you already have installed the AptecoPSFramework, make sure to re-install the dependencies in your settings file directory with `Install-AptecoPSFramework`
      Feature: Fixed the installation script to also install local and global packages
      Feature: Adding a default protocol handler that is recommended by Microsoft, if setting the setting `changeTLS` to `false`
      Feature: Added some hints about DuckDB in the readme.md
      Feature: Added a better handling for lib folder with other names or other paths than the default
      Feature: Added DuckDB functions to read data as pscustom or execute a scalar query
      Feature: DuckDB will be loaded automatically when plugin is loaded, otherwise you can use the function Import-Lib
      Fix: Added a where-object for CleverReach when not using additional parameters like proxy etc.
      Fix: Special characters are getting removed vom CleverReach mailing and group names via Regex `[^\w\s]`
0.2.1 Feature: New internal function for plugins to allow multipart uploads via `Prepare-MultipartUpload`
      Feature: Addition for Hubspot to load single or multiple properties by name in `Get-Property`
      Feature: New function for Hubspot to allow the loading of a pipeline
      Feature: New function for Hubspot to load "owners"
      Fix: Invoking hubspot has not used the correct headers which is now fixed
      Fix: Better error handling dependent from PS version in `Import-ErrorForResponseBody`^
      Fix: Improved input file handling for Salesforce plugin
      Fix: The get messages boilerplate was outdated and has now been updated
0.2.0 Added yaml as a new functionality to save and load settings - please make sure to install your dependencies again
      CleverReach - Fixed output for validations (showed 1 as valid when there is 0 valid entries)
      CleverReach - Putting failed entries also in log and returns it to Orbit Monitoring
      CleverReach - Fixed HTML Preview for global attributes
0.1.8 Changing CleverReach to support other mailing types than html/text
0.1.7 Adding a psmodulepath hardcoded to module and boilerplate as it seems to misinterpreted when called by C# runspaces
      Adding a flag to Hubspot to forward the input object name
0.1.6 Added a change for Hubspot to load associations into the properties
0.1.5 Fixed a problem in CleverReach when reading and parsing the headers from the csv
      Improved the CleverReach logging when something aborts
0.1.4 Changed the uploadsize from 2 to 80 for Hubspot
      Fix for loading properties of objects other than contacts in Hubspot
0.1.3 Changed Microsoft Dynamics Dataverse Integration to pagesize of 4500 instead of 3 for testing
      Removed -MergeArrays flag when merging settings in module and plugin -> now the arrays from the settings file are the important ones
      Adding hubspot to load CRM data with properties and search/filter, sync all of your data now!
      Hubspot list upload is now implemented through a list chooser in Orbit/PeopleStage and with use of the email address
      Changed the behaviour at Import-Settings, which looks now automatically for settings.json, otherwise you have to refer to it
0.1.2 New hashtable variable "variableCache" for plugins to share data/variables between functions
      Fix of saving oauth settings file path in the settings.json file
      Read-Only Support for Microsoft Dynamics DataVerse Web API
0.1.1 New version jump with more dependencies that have been implemented now: Install-Dependencies and Import-Dependencies, make sure to install those scripts before updating
      Fix for http calls so generic problematic are not repeating infinite
      Loading assemblies as dependencies, too
      Add a function/cmdlet to install plugins dependencies
      Adding more CleverReach api functions around token handling
      Support of PSOAuth for Salesforce SalesCloud and Microsoft Dynamics Dataverse, improved token refreshment for CleverReach
      Added enforced secret encryption for CleverReach, Salesforce and Microsoft
      Added automatic try of token refresh, if there is a http401 error
0.0.20 Exchanged the module/script path handling for the module itself and the boilerplate
       Improved the installation of dependencies with a new script
       Fix of $null when loading details of new attributes
0.0.19 Added script support for boilerplates
0.0.18 Added a new setting for CleverReach to put response log information into a separate logfile
       Added more documentation for CleverReach response download
...ReleaseNotes truncated...
'

    } # Ende der PSData-Hashtabelle

} # Ende der PrivateData-Hashtabelle

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}