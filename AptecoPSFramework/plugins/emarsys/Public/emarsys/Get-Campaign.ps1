
function Get-Campaign {
    [CmdletBinding()]
    param (

         [Parameter(Mandatory=$false)]
         [ValidateSet("batch_email", "transactional_email", IgnoreCase = $false)]
         [String]$BehaviorChannel = "batch_email"      # batch_email|transactional_email

        ,[Parameter(Mandatory=$false)]
         [ValidateSet("adhoc", "recurring", "newsletter", "onevent", "testmail", "multilanguage", "broadcast", IgnoreCase = $false)]
         [Array]$CampaignType = [Array]@()             # adhoc|recurring|newsletter|onevent|testmail|multilanguage|broadcast - multiple values are allowed

        ,[Parameter(Mandatory=$false)][Int]$Contactlist = 0                         #
        
        ,[Parameter(Mandatory=$false)]
         [ValidateSet(-1, 0, 1, IgnoreCase = $false)]
         [Int]$Launched = -1                           # 0|1

        ,[Parameter(Mandatory=$false)]
         [ValidateSet("", "html", "template", "block", IgnoreCase = $false)]
         [String]$ContentType = ""                     # html|template|block

        ,[Parameter(Mandatory=$false)]
         [ValidateSet(-1, 0, 1, IgnoreCase = $false)]
         [Int]$ShowDeleted = -1                        # 0|1
        
        ,[Parameter(Mandatory=$false)][String]$FromDate = ""                        # string like 2024-06-16
        ,[Parameter(Mandatory=$false)][String]$ToDate = ""                          # string like 2024-06-16
    )

    begin {

    }

    process {
        
        #-----------------------------------------------
        # DEFINE QUERY
        #-----------------------------------------------

        $query = [PSCustomObject]@{}


        If ( $Launched -in @(0,1) ) {
            $query | Add-Member -MemberType NoteProperty -Name "launched" -Value $Launched
        } elseif ( $Launched -eq -1 ) {
            # Set nothing
        } else {
            throw "Launched have to be 0 or 1"
        }


        If ( $BehaviorChannel -in @( "batch_email", "transactional_email" ) ) {
            $query | Add-Member -MemberType NoteProperty -Name "behavior_channel" -Value $BehaviorChannel
        } else {
            throw "BehaviorChannel is not valid"
        }

        
        $CampaignType | ForEach-Object {
            
            $ct = $_
            
            # Just check all types
            If ( $CampaignType -in @( "adhoc", "recurring", "newsletter", "onevent", "testmail", "multilanguage", "broadcast" ) ) {
            } else {
                throw "CampaignType is not valid"
            }

            $query | Add-Member -MemberType NoteProperty -Name "campaign_type" -Value ( $CampaignType -join "," )

        }


        $query | Add-Member -MemberType NoteProperty -Name "contactlist" -Value $Contactlist


        If ( $ContentType -in @("html", "template", "block") ) {
            $query | Add-Member -MemberType NoteProperty -Name "content_type" -Value $ContentType
        } elseif ( $ContentType -eq "" ) {
            # Set nothing
        } else {
            throw "Launched have to be html, template or block"
        }


        If ( $ShowDeleted -in @(0,1) ) {
            $query | Add-Member -MemberType NoteProperty -Name "showdeleted" -Value $ShowDeleted
        } elseif ( $ShowDeleted -eq -1 ) {
            # Set nothing
        } else {
            throw "showdeleted have to be 0 or 1"
        }


        
        If ( $FromDate -ne "" ) {
            $f = [Datetime]::Today
            If ( [Datetime]::TryParse($FromDate,[ref]$f) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "fromdate" -Value $f.ToString("yyyy-MM-dd")
            } else {
                throw "FromDate is not valid"
            }
        } else {
            # Set nothing
        }


        If ( $ToDate -ne "" ) {
            $t = [Datetime]::Today
            If ( [Datetime]::TryParse($ToDate,[ref]$t) -eq $true ) {
                $query | Add-Member -MemberType NoteProperty -Name "todate" -Value $t.ToString("yyyy-MM-dd")
            } else {
                throw "ToDate is not valid"
            }
        } else {
            # Set nothing
        }

        # TODO implement more query filters
        <#
        email_category
        is_rti
        parent_campaign_id
        root_campaign_id        
        status
        template
        #>
        

        #-----------------------------------------------
        # PREPARE PARAMETERS
        #-----------------------------------------------

        # Create params
        $params = [Hashtable]@{
            "Object" = "email"
            "Method" = "GET"
            "Query" = $query
        }

        # add verbose flag, if set
		If ( $PSBoundParameters["Verbose"].IsPresent -eq $true ) {
			$params.Add("Verbose", $true)
		}
        

        #-----------------------------------------------
        # REQUEST
        #-----------------------------------------------

        $campaigns = Invoke-EmarsysCore @params #-Object "field" -Path "translate/de"


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        # return
        $campaigns


    }

    end {

    }

}


