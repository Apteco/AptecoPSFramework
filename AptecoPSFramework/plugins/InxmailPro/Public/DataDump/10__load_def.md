```PowerShell
$loadDefs = [System.Collections.ArrayList]@(
    
    <#
    
    TODO [ ] create a template entry here
    
    #>

    # Full: Load all lists since a specific date
    # Delta: Load new lists with the link from the specific date
    [PSCustomObject]@{
        "description" = "lists"
        "object" = "lists" #/lists{?createdAfter,createdBefore}
        "urn" = "id"
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "onlyOnFirstLoad" = $false
                "parameters" = [hashtable]@{
                    "createdAfter" = $earliestDate
                    #"pageSize" = 3
                }
                "rememberUpcomingLink" = $true
                # do this to check if lists have been deleted or e.g. renamed
            }
            [PSCustomObject]@{
                "type" = "full"
                "onlyOnFirstLoad" = $false
                "parameters" = [hashtable]@{
                    "createdAfter" = $earliestDate
                    #"pageSize" = 3
                }
                "rememberUpcomingLink" = $true
                # do this to check if lists have been deleted or e.g. renamed
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "lists"  } ).link
                "rememberUpcomingLink" = $true
                # remember the lastID URL to receive new lists, or timestamps to see what changed since then
            }
        )
        "subObjects" = [System.Collections.ArrayList]@(
            [PSCustomObject]@{
                "description" = "recipientsOfList"
                "object" = [ScriptBlock]{
                    "recipients" # /sendings/{sendingId}/protocol
                }
                "urn" = "id"
                "parent" = [ScriptBlock]{ $parentObj.id }
                "filter" = [ScriptBlock]{ @("STANDARD";"DYANMIC") -contains $parentObj.type }
                "extract" = @(
                    [PSCustomObject]@{
                        "type" = "first"
                        "parameters" = [hashtable]@{
                            "subscribedTo" = [ScriptBlock]{ $parentObj.id }
                            #"pageSize" = 3
                        }
                        "rememberUpcomingLink" = $false
                    }
                    [PSCustomObject]@{
                        "type" = "full"
                        "parameters" = [hashtable]@{
                            "subscribedTo" = [ScriptBlock]{ $parentObj.id }
                            #"pageSize" = 3
                        }
                        "rememberUpcomingLink" = $false
                    }
                    [PSCustomObject]@{
                        "type" = "delta"
                        "parameters" = [hashtable]@{
                            "subscribedTo" = [ScriptBlock]{ $parentObj.id }
                            #"pageSize" = 3
                        }
                        "rememberUpcomingLink" = $false
                    }
                )
            }
        )
    }

    # Full: Load all mailings since a specific date
    # Delta: Load new mailings with the link from the specific date
    [PSCustomObject]@{
        "description" = "mailings"
        "object" = "mailings" 
        "urn" = "id"
        "parent" = [ScriptBlock]{ $_.listId }
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "createdAfter" = $earliestDate
                    "embedded" = "inx:response-statistics,inx:sending-statistics"
                    #"pageSize" = 3
                }
                "rememberUpcomingLink" = $true
                # do this to check if mailings have been deleted or e.g. renamed
            }
            [PSCustomObject]@{
                "type" = "full"
                "parameters" = [hashtable]@{
                    "createdAfter" = $earliestDate
                    "embedded" = "inx:response-statistics,inx:sending-statistics"
                    #"pageSize" = 3
                }
                "rememberUpcomingLink" = $true
                # do this to check if mailings have been deleted or e.g. renamed
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "mailings"  } ).link
                "rememberUpcomingLink" = $true
                # remember the lastID URL to receive new lists, or timestamps to see what changed since then
            }
        )
    }
    # Full: Load all attributes, this is also used for loading the recipients attributes
    # Delta: Load all attributes, this is also used for loading the recipients attributes
    [PSCustomObject]@{
        "description" = "attributes"
        "object" = "attributes" 
        "urn" = "id"
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "rememberUpcomingLink" = $false
            }
            [PSCustomObject]@{
                "type" = "daily"
                "rememberUpcomingLink" = $false
            }
            [PSCustomObject]@{
                "type" = "full"
                "rememberUpcomingLink" = $false
            }
            [PSCustomObject]@{
                "type" = "delta"
                "rememberUpcomingLink" = $false
            }
        )
    }

    # Full: Load all sendings (with protocol) after a specific date, if it is the first load
    # Delta: Load all new sendings (with protocol) with the upcoming link
    [PSCustomObject]@{
        "description" = "sendings"
        "object" = "sendings" #/sendings{?mailingIds,listIds,sendingsFinishedBeforeDate,sendingsFinishedAfterDate}
        "urn" = "id"
        "parent" = [ScriptBlock]{ $_.mailingId }
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "sendingsFinishedAfterDate" = $earliestDate
                    #"pageSize" = 3
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "sendings" } ).link
                # remember the lastID URL to receive new lists
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "sendings" } ).link
                # remember the lastID URL to receive new lists
                "rememberUpcomingLink" = $true
            }
        )
        "subObjects" = [System.Collections.ArrayList]@(
            [PSCustomObject]@{
                "description" = "sendingsprotocol"
                "object" = [ScriptBlock]{
                    "sendings/$( $parentObj.id )/protocol" # /sendings/{sendingId}/protocol
                }
                "urn" = "recipientId"
                "parent" = [ScriptBlock]{ $parentObj.id }
                "extract" = @(
                    [PSCustomObject]@{
                        "type" = "first"
                    }
                    [PSCustomObject]@{
                        "type" = "full"
                    }
                    [PSCustomObject]@{
                        "type" = "delta"
                    }
                )
            }
        )
    }

    # Full: Load all recipients with all attributes (which need to be loaded beforehand in this process) - Do this to check if recipients have been deleted
    # Delta: Load all recipients since a specific modified date. Using the upcoming link would only load new recipients, but not changed ones
    [PSCustomObject]@{
        "description" = "recipients"
        "object" = "recipients" #/recipients{?attributes,subscribedTo,lastModifiedSince,email,attributes.attributeName,trackingPermissionsForLists,subscriptionDatesForLists,unsubscriptionDatesForLists}
        "urn" = "id"
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "attributes" = [ScriptBlock]{
                        ( $inxArr | where { $_.object -eq "attributes"  } | ForEach { ConvertFrom-Json $_.payload  } | select name ).name -join ","
                    }
                    #"lastModifiedSince" = $lastLoad
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "daily" # TODO [ ] Is there a better way to recognise removed records?
                "parameters" = [hashtable]@{
                    "attributes" = [ScriptBlock]{
                        ( $inxArr | where { $_.object -eq "attributes"  } | ForEach { ConvertFrom-Json $_.payload  } | select name ).name -join ","
                    }
                    #"lastModifiedSince" = $lastLoad
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "parameters" = [hashtable]@{
                    "attributes" = [ScriptBlock]{
                        ( $inxArr | where { $_.object -eq "attributes"  } | ForEach { ConvertFrom-Json $_.payload  } | select name ).name -join ","
                    }
                    "lastModifiedSince" = $lastLoad
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                #"nextLink" = $lastSession.nextLinks.where( { $_.name -eq "recipients"  } ).link
                "parameters" = [hashtable]@{
                    "attributes" = [ScriptBlock]{
                        ( $inxArr | where { $_.object -eq "attributes"  } | ForEach { ConvertFrom-Json $_.payload  } | select name ).name -join ","
                    }
                    "lastModifiedSince" = $lastLoad
                }
                "rememberUpcomingLink" = $true
            }
        )
    }

    # Full: Load all subscription events after a specific date, if it is the first load
    # Delta: Load all new subscription events with the upcoming link
    [PSCustomObject]@{
        "description" = "subscriptions"
        "object" = "events/subscriptions" # /events/subscriptions{?listId,startDate,endDate,types,embedded,recipientAttributes}
        "urn" = "id"
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "startDate" = $earliestDate
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "events/subscriptions"  } ).link
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "events/subscriptions"  } ).link
                "rememberUpcomingLink" = $true
            }
        )
    }

    # Full: Load all unsubscription events after a specific date, if it is the first load
    # Delta: Load all new unsubscription events with the upcoming link
    [PSCustomObject]@{
        "description" = "unsubscriptions"
        "object" = "events/unsubscriptions"
        "urn" = "id"
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "startDate" = $earliestDate
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "events/unsubscriptions"  } ).link
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "events/unsubscriptions"  } ).link
                "rememberUpcomingLink" = $true
            }
        )
    }

    # Full: Load all tracking permission events, there are only new events and existing ones cannot be changed, so only loading the full at the first load
    # Delta: Load all new tracking permission events events with the upcoming link
    [PSCustomObject]@{
        "description" = "tracking-permissions"
        "object" = "events/tracking-permissions"
        "urn" = "id"
        "parent" = [ScriptBlock]{ $_.listId }
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "events/tracking-permissions"  } ).link
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "events/tracking-permissions"  } ).link
                "rememberUpcomingLink" = $true
            }
        )
    }

    # Full: Load all tracking permission events, there are only new events and existing ones cannot be changed, so only loading the full at the first load
    # Delta: Load all new tracking permission events events with the upcoming link
    [PSCustomObject]@{
        "description" = "target-groups"
        "object" = "target-groups"
        "urn" = "id"
        "parent" = [ScriptBlock]{ $_.listId }
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "target-groups"  } ).link
                "rememberUpcomingLink" = $true
            }
        )
    }

    # Full: Load all bounces after a specific date, if it is the first load
    # Delta: Load all new bounces events with the upcoming link
    [PSCustomObject]@{
        "description" = "bounces"
        "object" = "bounces"
        "urn" = "id"
        "parent" = [ScriptBlock]{ $_.sendingId }
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "startDate" = $earliestDate
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "bounces"  } ).link
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "bounces"  } ).link
                "rememberUpcomingLink" = $true
            }
        )
    }

    # Full: Load all bounces after a specific date, if it is the first load
    # Delta: Load all new bounces events with the upcoming link
    [PSCustomObject]@{
        "description" = "opens"
        "object" = "web-beacon-hits"
        "urn" = "id"
        "parent" = [ScriptBlock]{ $_.sendingId }
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "startDate" = $earliestDate
                    "embedded" = "inx:recipient"
                    "recipientAttributes" = @("urn") -join ","
                    "trackedOnly" = $true
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "web-beacon-hits"  } ).link
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "web-beacon-hits"  } ).link
                "rememberUpcomingLink" = $true
            }
        )
    }

    # Full: Load all bounces after a specific date, if it is the first load
    # Delta: Load all new bounces events with the upcoming link
    [PSCustomObject]@{
        "description" = "clicks"
        "object" = "clicks"
        "urn" = "id"
        "parent" = [ScriptBlock]{ $_.sendingId }
        "extract" = @(
            [PSCustomObject]@{
                "type" = "first"
                "parameters" = [hashtable]@{
                    "startDate" = $earliestDate
                    "embedded" = "inx:recipient"
                    "recipientAttributes" = @("urn") -join ","
                    "trackedOnly" = $true
                }
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "full"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "clicks"  } ).link
                "rememberUpcomingLink" = $true
            }
            [PSCustomObject]@{
                "type" = "delta"
                "nextLink" = $lastSession.nextLinks.where( { $_.name -eq "clicks"  } ).link
                "rememberUpcomingLink" = $true
            }
        )
    }


)

```