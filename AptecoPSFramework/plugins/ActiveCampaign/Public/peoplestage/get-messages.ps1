

function Get-Messages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
    )

    begin {


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "GETMESSAGES"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }

        #-----------------------------------------------
        # DEPENDENCIES
        #-----------------------------------------------

        #...

    }

    process {

        #-----------------------------------------------
        # LOAD MAILINGS
        #-----------------------------------------------

        # TODO Add a switch for tags/events etc.

        $tags = get-tag | select-object id, @{name="name";expression={ $_.tag }}


        $mailings = [System.Collections.ArrayList]@()
        $mailings.AddRange($tags)

        <#
        [void]$mailings.Add(
            [PSCustomObject]@{
                "id" = "a"
                "name" = "add"
            }
        )
        [void]$mailings.Add(
            [PSCustomObject]@{
                "id" = "r"
                "name" = "remove"
            }
        )
        #>

        # Load and filter list into array of mailings objects
        $mailingsList = [System.Collections.ArrayList]@()
        $mailings | ForEach-Object {
            $mailing = $_
            [void]$mailingsList.add(
                [Mailing]@{
                    mailingId=$mailing.id
                    mailingName=$mailing.name
                }
            )
        }

        # Transform the mailings array into the needed output format
        $columns = @(
            @{
                name="id"
                expression={ $_.mailingId }
            }
            @{
                name="name"
                expression={ $_.toString() }
            }
        )

        $messages = [System.Collections.ArrayList]@()
        [void]$messages.AddRange(@( $mailingsList | Select-Object $columns ))

        If ( $messages.count -gt 0 ) {

            Write-Log "Loaded $( $messages.Count ) messages" -severity INFO #-WriteToHostToo $false

        } else {

            $msg = "No messages loaded -> please check!"
            Write-Log -Message $msg -Severity ERROR
            throw [System.IO.InvalidDataException] $msg

        }

        # Return
        $messages

    }

    end {

    }

}

