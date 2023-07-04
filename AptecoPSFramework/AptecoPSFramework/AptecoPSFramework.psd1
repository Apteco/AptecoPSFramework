﻿#
# Module manifest for module 'MeasureRows'
#
# Generated by: florian.von.bracht@apteco.de
#
# Generated on: 28.10.2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'AptecoPSFramework.psm1'

# Version number of this module.
ModuleVersion = '0.0.6'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'ada4a156-dea2-4821-9c8b-e7ef33a7fa46'

# Author of this module
Author = 'florian.von.bracht@apteco.de'

# Company or vendor of this module
CompanyName = 'Apteco GmbH'

# Copyright statement for this module
Copyright = '(c) 2023 Apteco GmbH. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Apteco PS Modules - Framework

More description to follow...'

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
    #"WriteLog"
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
    "Set-ProcessIdentifier"
    "Set-Settings"
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

        # Eine URL zur Hauptwebsite für dieses Projekt.
        ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/dev/AptecoPSFramework'

        # Eine URL zu einem Symbol, das das Modul darstellt.
        IconUri = 'https://www.apteco.de/sites/default/files/favicon_3.ico'

        # 'ReleaseNotes' des Moduls
        ReleaseNotes = '
0.0.6 Added tags support for uploading data and preview
      Fixed a bug in the CleverReach Preview regarding new attributes
0.0.5 Added CleverReach Email Preview
0.0.4 Changed URLs
      Many improvements and fixes for the CleverReach plugin
      Boilerplate fixes for loading psmodulepath environment variable
0.0.3 Automatically load new plugin folders and save them in the settings
      Support response gathering for CleverReach Plugin
0.0.2 Small fixes after testing
0.0.1 Initial release of Apteco PS module through psgallery
'

    } # Ende der PSData-Hashtabelle

} # Ende der PrivateData-Hashtabelle

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}