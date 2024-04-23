
function Remove-Contact {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
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

            "florian.von.bracht@apteco.tld"
            "florian.friedrichs@apteco.tld"

        )

        $res = $emarsys.deleteContact("3", $a)

        $res

    }

    end {

    }

}


