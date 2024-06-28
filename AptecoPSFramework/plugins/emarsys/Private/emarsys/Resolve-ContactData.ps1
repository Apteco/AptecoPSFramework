
function Resolve-ContactData {
    [CmdletBinding()]
    param (
          [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]$FetchList
         ,[Parameter(Mandatory=$false)][Switch]$IgnoreErrors = $false
    )

    begin {

        # fill fields into variable cache or just get it
        If ( $Script:variableCache.fields -eq $null ) {

            # Create a lookup hashtable for field names
            $fieldHashtable = [hashtable]@{}
            get-field | ForEach-Object {
                $fieldHashtable.add($_.id,$_.name)
            }
            $Script:variableCache.Add("fields",$fieldHashtable)

        } else {

            $fieldHashtable = $Script:variableCache.fields

        }

    }

    process {

        $res = [System.Collections.ArrayList]@()
        $FetchList.result | ForEach-Object {

            $row = $_

            $newRow = [PSCustomObject]@{
                "id" = $row.id      # always returned
                "uid" = $row.uid    # always returned
            }

            $row.PSObject.Properties | Where-Object { $_.MemberType -eq "NoteProperty" -and $_.Name -notin "id","uid" } | ForEach-Object {
                #$v = $_
                $newRow | Add-Member -MemberType NoteProperty -Name $fieldHashtable[[int]$_.Name]  -Value $_.Value
            }

            [void]$res.Add($newRow)

        }

        # return directly
        If ( $IgnoreErrors -eq $true ) {
            $res
        } else {
            [PSCustomObject]@{
                "errors" = $fetchList.errors
                "result" =  $res
            }
        }

    }

}