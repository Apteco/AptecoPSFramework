
$psScripts = [Array]@(
    "Install-Dependencies"
    "Import-Dependencies"
)

$psModules = [Array]@(
    "WriteLog"
    "MeasureRows"
    "EncryptCredential"
    "ExtendFunction"
    "ConvertUnixTimestamp"
    "powershell-yaml"
    "InvokeWebRequestUTF8"
    #"Microsoft.PowerShell.Utility"
    #"PSOAUth"  # is defined in the local plugins where it is needed
    #"PackageManagement"
    #"PowerShellGet"
    "ConvertStrings"
    "SimplySql" # Added to use for job management instead of DuckDB which only support x64
    "MergeHashtable"
    "MergePSCustomObject"
)


$psGlobalPackages = [Array]@(

)


# Define either a simple string or provide a pscustomobject with a specific version number
$psLocalPackages = [Array]@(
    <#
    [PSCustomObject]@{
        name="Npgsql"
        version = "4.1.12"
        includeDependencies = $true
    }

    [PSCustomObject]@{
        name="MailKit"
        #version = "4.1.12"
        includeDependencies = $false
    }

    [PSCustomObject]@{
        name="System.Data.Sqlite"
        #version = "4.1.12"
        includeDependencies = $false
    }

    #>

    "DuckDB.NET.Bindings.Full"
    "DuckDB.NET.Data.Full"

)

$psAssemblies = [Array]@(
    "System.Web.Extensions"     # Needed for deserialisation of ConvertFrom-Json
)