




function Get-ContactData {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        [Parameter(Mandatory=$true)][System.Collections.ArrayList]$InputEmail
        
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
        $fields = [System.Collections.ArrayList]@(1,2,3,31,9,46,11,12)

        <#
        $keys = [System.Collections.ArrayList]@(378808151,378808960)
        $fetch = $emarsys.getContactData("id",$fields,$keys)
        #>

        $fetch = $emarsys.getContactData("id",$fields,$InputEmail)

        $fetch

    }

    end {

    }

}


