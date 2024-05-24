
function Get-Contact {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][Switch] $DebugMode = $false
        #[Parameter(Mandatory=$true)][Int] $ListId
        [Parameter(Mandatory=$false)][Switch] $IncludeLinks = $false
    )

    begin {
        # https://developers.activecampaign.com/reference/list-all-contacts
        $resource = "contacts"
    }

    process {

        # TODO Implement improved paging
        <#
        Accounts with many Contacts may encounter slower responses when using the offset parameter to paginate with this endpoint. For best performance, sort using orders[id]=ASC and use the id_greater parameter to paginate.

        This is especially important when calling this endpoint frequently, such as when retrieving many or all Contacts from an account.

        #>

        # TODO maybe add another function based on this one and add custom fields as separate columns, merged via DuckDB

        $query = [PSCustomObject]@{
            "orders[id]"="ASC"
        }

        $contact = Invoke-AC -Resource $resource -Query $query -Paging

        # meta contains @{page_input=; total=0; sortable=True}

        # return
        If ( $IncludeLinks -eq $true ) {
            $contact.$resource
        } else {
            $contact.$resource | Select-Object * -ExcludeProperty "links"
        }

    }

    end {

    }

}


