
# TODO Put this into separate module and publish it

# The function uses the "Left" one as the kind of master and extends it with "Right"
# By default, properties in "Left" get overwritten, but with the flag "AddPropertiesFromRight"
# it also adds properties from the right one
# add the -verbose flag if you want to know more whats about to happen
function Join-PSCustomObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
         [Parameter(Mandatory=$true,ValueFromPipeline)][PSCustomObject]$Left
        ,[Parameter(Mandatory=$true)][PSCustomObject]$Right
        ,[Parameter(Mandatory=$false)][Switch]$AddPropertiesFromRight = $false
        ,[Parameter(Mandatory=$false)][Switch]$MergePSCustomObjects = $false
        ,[Parameter(Mandatory=$false)][Switch]$MergeArrays = $false
        ,[Parameter(Mandatory=$false)][Switch]$MergeHashtables = $false
    )

    begin {

        if ( $null -eq $Left ) {
            # return
            return $null
        }

        if ( $null -eq $Right ) {
            # return
            Write-Warning "-Right is null!"
        }

    }

    process {

        # Create an empty object
        $joined = [PSCustomObject]@{}

        # Go through the left object
        If ( $Left -is [PSCustomObject] ) {

            # Read all properties
            $leftProps = $Left.PsObject.Properties.name
            $rightProps = $Right.PsObject.Properties.name

            # Compare
            $compare = Compare-Object -ReferenceObject $leftProps -DifferenceObject $rightProps -IncludeEqual

            # Go through all properties
            $compare | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object {
                $propLeft = $_.InputObject
                $joined | Add-Member -MemberType NoteProperty -Name $propLeft -Value $Left.($propLeft)
                Write-Verbose "Add '$( $propLeft )' from left side"
            }

            # Now check if we can add more properties
            If ( $AddPropertiesFromRight -eq $true ) {
                $compare | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object {
                    $propRight = $_.InputObject
                    $joined | Add-Member -MemberType NoteProperty -Name $propRight -Value $Right.($propRight)
                    Write-Verbose "Add '$( $propRight )' from right side"
                }
            }

            # Now overwrite existing values or check to go deeper if needed
            $compare | Where-Object { $_.SideIndicator -eq "==" } | ForEach-Object {

                $propEqual = $_.InputObject

                # Count the props first
                $countLeft = 0
                If ( $Left.($propEqual) -is [PSCustomObject] ) {
                    $countLeft += @( $Left.($propEqual).psobject.properties | where-object { $_.MemberType -eq "NoteProperty" } ).Count
                } elseif ( $Left.($propEqual) -is [System.Collections.Specialized.OrderedDictionary] -or $Left.($propEqual) -is [hashtable]) {
                    $countLeft += @( $Left.($propEqual).Keys ).Count
                }
                $countRight = 0
                If ( $Right.($propEqual) -is [PSCustomObject] ) {
                    $countRight += @( $Right.($propEqual).psobject.properties | where-object { $_.MemberType -eq "NoteProperty" } ).Count
                } elseif ( $Right.($propEqual) -is [System.Collections.Specialized.OrderedDictionary] -or $Right.($propEqual) -is [hashtable]) {
                    $countRight += @( $Right.($propEqual).Keys ).Count
                }

                # Go through the different cases
                If ( $MergePSCustomObjects -eq $true -and ( $Left.($propEqual) -is [PSCustomObject] -or $Left.($propEqual) -is [System.Collections.Specialized.OrderedDictionary] ) -and ( $Right.($propEqual) -is [PSCustomObject] -or $Right.($propEqual) -is [System.Collections.Specialized.OrderedDictionary] ) -and $countRight -gt 0 ) {

                    Write-Verbose "Going recursively into '$( $propEqual )'"

                    # Recursively call this function, if it is nested ps custom
                    $params = [Hashtable]@{
                        "Left" = [PSCustomObject]( $Left.($propEqual) )
                        "Right" = [PSCustomObject]( $Right.($propEqual) )
                        "AddPropertiesFromRight" = $AddPropertiesFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Join-PSCustomObject @params
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $recursive

                } elseif ( $MergeArrays -eq $true -and $Left.($propEqual) -is [Array] -and $Right.($propEqual) -is [Array] ) {

                    Write-Verbose "Merging arrays from '$( $propEqual )'"

                    # Merge array
                    $newArr = [Array]@( $Left.($propEqual) + $Right.($propEqual) ) | Sort-Object -unique
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $newArr

                } elseif ( $MergeArrays -eq $true -and $Left.($propEqual) -is [System.Collections.ArrayList] -and $Right.($propEqual) -is [System.Collections.ArrayList] ) {

                    Write-Verbose "Merging arraylists from '$( $propEqual )'"

                    # Merge arraylist
                    $newArr = [System.Collections.ArrayList]@()
                    $newArr.AddRange($Left.($propEqual))
                    $newArr.AddRange($Right.($propEqual))
                    $newArrSorted = [System.Collections.ArrayList]@( $newArr | Sort-Object -Unique )
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $newArrSorted

                } elseif ( $MergeHashtables -eq $true -and $Left.($propEqual) -is [hashtable] -and $Right.($propEqual) -is [hashtable] -and $countRight -gt 0) {
                    
                    Write-Verbose "Merging hashtables from '$( $propEqual )'"

                    # Recursively call this function, if it is nested hashtable
                    $params = [Hashtable]@{
                        "Left" = $Left.($propEqual)
                        "Right" = $Right.($propEqual)
                        "AddKeysFromRight" = $AddPropertiesFromRight
                        "MergePSCustomObjects" = $MergePSCustomObjects
                        "MergeArrays" = $MergeArrays
                        "MergeHashtables" = $MergeHashtables
                    }
                    $recursive = Join-Hashtable @params
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $recursive

                } elseif ( $countLeft -gt 0 -and $countRight -eq 0 ) {

                    # just overwrite existing values if datatypes of attribute are different or no merging is wished
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $Left.($propEqual)
                    Write-Verbose "Overwrite '$( $propEqual )' with value from left side"
                    #Write-Verbose "Datatypes of '$( $propEqual )' are not the same on left and right"                    
                
                } else {

                    # just overwrite existing values if datatypes of attribute are different or no merging is wished
                    $joined | Add-Member -MemberType NoteProperty -Name $propEqual -Value $Right.($propEqual)
                    Write-Verbose "Overwrite '$( $propEqual )' with value from right side"
                    #Write-Verbose "Datatypes of '$( $propEqual )' are not the same on left and right"

                }


            }

        }

        # return
        $joined

    }

    end {

    }
}


#-----------------------------------------------
# TESTING PSCUSTOMOBJECTS
#-----------------------------------------------
<#
$left = [PSCustomObject]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "testnull" = $null
    "emptyArr" = $null
    "arr" = [Array]@("a","b","c")
    "nested" = [PSCustomObject]@{
        "firstname" = "Flo"
    }
    "ht" = [hashtable]@{
        "firstname" = "Florian"
        "lastname" = "Friedrichs"
    }
    "filledAndEmpty" = [PSCustomObject]@{
        "firstname" = "Flo"
    }
}

$right = [PSCustomObject]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "Postcode" = 52080
    "emptyArr" = [Array]@()
    "nested" = [PSCustomObject]@{
        "lastname" = "von Bracht"
    }
    "arr" = [Array]@("d","e","f")
    "ht" = [hashtable]@{
        "lastname" = "von Bracht"
        "Street" = "Schaumainkai 87"
    }
    "filledAndEmpty" = [PSCustomObject]@{
    }
}

$res = Join-PSCustomObject -Left $left -Right $right -AddPropertiesFromRight -MergePSCustomObject -MergeArrays -verbose -MergeHashtables
ConvertTo-Json -InputObject $res

#>
