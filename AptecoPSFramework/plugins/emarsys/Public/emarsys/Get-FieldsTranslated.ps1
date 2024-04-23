




function Get-FieldsTranslated {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String] $Language
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

        # TODO remove this later
        $stringSecure = ConvertTo-SecureString -String ( Convert-SecureToPlaintext $Script:settings.login.secret ) -AsPlainText -Force
        $cred = [pscredential]::new( $Script:settings.login.username, $stringSecure )

        #$emarsys = $Script:variableCache.emarsys

        $fields = Invoke-emarsys -cred $cred -uri "$( $Script:settings.base )field/translate/$( $Language )" -method "Get"

        $fields

    }

    end {

    }

}


