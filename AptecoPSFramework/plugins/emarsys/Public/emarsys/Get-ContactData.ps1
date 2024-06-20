




function Get-ContactData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][Array]$KeyValues
        ,[Parameter(Mandatory=$false)][String]$KeyId = "email" # Identifies the contact by their id, uid, or the name/integer id of a custom field, such as email
        ,[Parameter(Mandatory=$false)][Array]$Fields = @("id","email")
        ,[Parameter(Mandatory=$false)][Switch]$ResolveFields = $false
        ,[Parameter(Mandatory=$false)][Switch]$IgnoreErrors = $false

    )

    begin {

        #Invoke-EmarsysLogin

    }

    process {

        #$emarsys = $Script:variableCache.emarsys
        #$fields = [System.Collections.ArrayList]@(1,2,3,31,9,46,11,12)

        <#
        $keys = [System.Collections.ArrayList]@(378808151,378808960)
        $fetch = $emarsys.getContactData("id",$fields,$keys)
        #>

        #$keys = [System.Collections.ArrayList]@("florian.von.bracht@apteco.tld","florian.friedrichs@apteco.tld")
        #ä$fetch = $emarsys.getContactData("3",$fields,$InputEmail)
        #$fetch = $emarsys.getContactData("id",$fields,$InputEmail)

        #$fetch


        $params = [Hashtable]@{
            "Object" = "contact"
            "Method" = "POST"
            "Path" = "getdata"
            "Body" = [PSCustomObject]@{
                'fields' = $Fields
                'keyId' = $KeyId
                'keyValues' = $KeyValues
            }
        }

        # add verbose flag, if set
        If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
            $params.Add("Verbose", $true)
        }

        # Request list creation
        $fetchList = Invoke-EmarsysCore @params

        # Rewrite result
        If ( $ResolveFields -eq $true  ) {

            # Create a lookup hashtable for field names
            $fieldHashtable = [hashtable]@{}
            get-field | ForEach-Object { $fieldHashtable.add($_.id,$_.name) }

            $res = [System.Collections.ArrayList]@()
            $fetchList.result | ForEach-Object {
    
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

            # return
            If ( $IgnoreErrors -eq $true ) {
                $res
            } else {
                [PSCustomObject]@{
                    "errors" = $fetchList.errors
                    "result" =  $res
                }
            }
    
        } else {
            If ( $IgnoreErrors -eq $true ) {
                $res.result
            } else {
                $fetchList
            }
        }



        

        

    }

    end {

    }

}


