
function Add-Contact {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][Array] $Add
    )

    begin {

        Invoke-EmarsysLogin

    }

    process {

         #| Out-GridView -PassThru | Select -first 20
# $fields | Out-GridView
# #$fields | Export-Csv -Path ".\fields.csv" -Encoding Default -NoTypeInformation -Delimiter "`t"
# #$fields | Select @{name="field_id";expression={ $_.id }}, @{name="fieldname";expression={$_.name}} -ExpandProperty choices | Export-Csv -Path ".\fields_choices.csv" -Encoding Default -NoTypeInformation -Delimiter "`t"

# $c = Invoke-emarsys -cred $cred -uri "$( $settings.base )field/translate/de" -method Get

        $emarsys = $Script:variableCache.emarsys

        #$fields = $emarsys.getFields($false)

        $a = [System.Collections.ArrayList]@(
<#
            [PSCustomObject]@{
                "1" = "Florian"
                "2" = "von Bracht"
                "3" = "florian.von.bracht@apteco.tld"
                "31" = $null
            }

            [PSCustomObject]@{
                "1" = "Florian"
                "2" = "Friedrichs"
                "3" = "florian.friedrichs@apteco.tld"
                "31" = $null
            }
#>
        )
        $a.AddRange($Add)

        $res = $emarsys.createContact("3","890495209", $a)

        $res

    }

    end {

    }

}


