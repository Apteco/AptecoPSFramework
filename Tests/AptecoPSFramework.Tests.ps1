

Describe "AptecoPSFramework Module Import and Installation" {

    It "Module should throw an error when imported if dependencies are missing" {

        # Add path to the module
        $modulePath = "$PSScriptRoot/../AptecoPSFramework/AptecoPSFramework.psd1"

        # Uninstall a module that is a dependency to simulate missing dependencies
        Uninstall-Module MeasureRows -AllVersions -Force -ErrorAction SilentlyContinue

        # Import the module
        { Import-Module $modulePath -Force } | Should -Throw

        # Clean up by removing the module if it was partially loaded
        Remove-Module AptecoPSFramework -Force -ErrorAction SilentlyContinue

    }
<#
    It "Install-AptecoPSFramework should install dependencies without error" {

        { Install-AptecoPSFramework -Force } | Should -Not -Throw
    }


    $exportedFunctions = @(
        "Add-PluginFolder",
        "Export-Settings",
        "Get-Debug",
        "Get-Plugin",
        "Get-PluginFolders",
        "Get-Plugins",
        "Get-ProcessIdentifier",
        "Get-Settings",
        "Import-Plugin",
        "Import-Settings",
        "Install-AptecoPSFramework",
        "Register-Plugins",
        "Set-DebugMode",
        "Set-ExecutionDirectory",
        "Set-Settings",
        "Install-Plugin",
        "Open-DuckDBConnection",
        "Get-DuckDBConnection",
        "Close-DuckDBConnection",
        "Read-DuckDBQueryAsReader",
        "Read-DuckDBQueryAsScalar",
        "Invoke-DuckDBQueryAsNonExecute",
        "Add-DuckDBConnection",
        "Get-DebugMode",
        "Import-Lib",
        "Add-JobLog",
        "Get-JobLog",
        "Update-JobLog",
        "Set-JobLogDatabase",
        "Close-JobLogDatabase"
    )

    foreach ($func in $exportedFunctions) {
        It "Exports function $func" {
            Get-Command $func -Module AptecoPSFramework | Should -Not -BeNullOrEmpty
        }
    }

    It "Get-Settings returns a hashtable or object" {
        $result = Get-Settings
        ($result -is [hashtable] -or $result -is [psobject]) | Should -BeTrue
    }

    It "Set-DebugMode can be called without error" {
        { Set-DebugMode -Debug $true } | Should -Not -Throw
    }

    It "Get-DebugMode returns a boolean" {
        $result = Get-DebugMode
        ($result -is [bool]) | Should -BeTrue
    }

    # Add more tests for other functions as needed, e.g.:
    # It "Add-PluginFolder can be called without error" {
    #     { Add-PluginFolder -Path "$PSScriptRoot/../Plugins" } | Should -Not -Throw
    # }
#>
}

