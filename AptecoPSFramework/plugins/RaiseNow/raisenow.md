
Documentation: https://docs.raisenow.com/api/

Obtain a token with your client id and client secret

```PowerShell
$clientId = ""
$clientSecret = ""
$body = [PScustomobject]@{"grant_type"="client_credentials";"client_id"=$clientId;"client_secret"=$clientSecret}
$t = irm -uri "https://api.raisenow.io/oauth2/token" -Method Post -Body ( $body | ConvertTo-Json ) -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"}

$t.access_token

```

Token is valid for 3600 seconds

List organisations just as a test

```PowerShell
irm -uri "https://api.raisenow.io/organisations" -Method Get -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"}
```

List accounts

```PowerShell
irm -uri "https://api.raisenow.io/accounts" -Method Get -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"}
```

List subscription plans

```PowerShell
irm -uri "https://api.raisenow.io/subscription-plans" -Method Get -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"}
```

List your supporters

```PowerShell
irm -uri "https://api.raisenow.io/supporters" -Method Get -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"}
```



Filter for donations by creation date
https://docs.raisenow.com/partner-integrations/search/#field-inclusion-and-exclusion

```PowerShell

# Just list donations
$search = [PSCustomObject]@{
    "query" = [PSCustomObject]@{
        '$range' = [PSCustomObject]@{
            "created" = [PSCustomObject]@{
                #"lt" = "2024-04-23",
                "gt" = "1700000000" #"2024-01-01",
                #"format" = "yyyy-MM-dd"
            }
        }
    }
    "sort" = [Array]@(
        [PSCustomObject]@{
            "field" = "created"
            "field_type" = "numeric" # string|numeric|boolean
            "direction" = "asc" # asc|desc
        }
    )
    "size" = 100        # max 10k records and 10MB
    "from" = 0
    "includes" = [Array]@()
    "excludes" = [Array]@("charged_by")
}

$searchJson = ConvertTo-Json -InputObject $search -Depth 99

$payments = irm -uri "https://api.raisenow.io/search/payments" -Method Post -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"} -body $searchJson


# To count the donations after a timestamp, use this query

$search = [PSCustomObject]@{
    "query" = [PSCustomObject]@{
        '$range' = [PSCustomObject]@{
            "created" = [PSCustomObject]@{
                #"lt" = "2024-04-23",
                "gt" = "1700000000" #"2024-01-01",
                #"format" = "yyyy-MM-dd"
            }
        }
    }
    "aggs" = [PSCustomObject]@{
        "maxtimestamp" = 
            [PSCustomObject]@{
                "type" = "range"
                "field" = "created"
                "ranges"= [Array]@(
                    [PSCustomObject]@{
                        "from" = "1700000000"
                        #"to" = "1799999999"
                    }
                )
                "stats" = [PSCustomObject]@{
                    "createdstats" = "created"
                }
            }
    }
    "sort" = [PSCustomObject]@{
            "uuid" = "desc"
    }
    "size" = 0        # max 10k records and 10MB
    "from" = 0
    "includes" = [Array]@()
    "excludes" = [Array]@()
}

$searchJson = ConvertTo-Json -InputObject $search -Depth 99

$count = irm -uri "https://api.raisenow.io/search/payments" -Method Post -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"} -body $searchJson



```

Get a specific transaction/donation

```PowerShell
irm -uri "https://api.raisenow.io/payments/0b484f30-7a62-4d66-b808-a078ae158ef4" -Method Get -ContentType "application/json" -Headers @{"Accept-Encoding"="gzip"; "Authorization" = "Bearer $( $t.access_token )"}
```

