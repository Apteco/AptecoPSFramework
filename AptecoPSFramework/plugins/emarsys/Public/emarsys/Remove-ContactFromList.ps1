
function Remove-ContactFromList {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][Array] $Remove
        ,[Parameter(Mandatory=$true)][Int] $ListId
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

        $a = [System.Collections.ArrayList]@()
        $a.AddRange($Remove)

        #$res = $emarsys.deleteContactFromList("3", 31000652, $a)
        $res = $emarsys.deleteContactFromList("3", $ListId, $a)

        
        #$res = $emarsys.deleteContactFromList("id", 31000652, $a)

        $res

    }

    end {

    }

}


