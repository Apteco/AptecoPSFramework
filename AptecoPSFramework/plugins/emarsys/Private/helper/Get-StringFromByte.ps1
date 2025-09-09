
# transform bytes into hexadecimal string (e.g. for hash values)


function Get-StringFromByte() {

    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$false)][Byte[]]$byteArray = "https://api.emarsys.net/api/v2/"  # default url to use
    )

    $stringBuilder = ""
    $byteArray | ForEach-Object { $stringBuilder += $_.ToString("x2") }

    $stringBuilder

}

# Deprecated function call
function getStringFromByte($byteArray) {

    Get-StringFromByte -byteArray $byteArray

}