<#
$stringSecure = ConvertTo-SecureString -String ( Get-SecureToPlaintext $settings.login.secret ) -AsPlainText -Force
    $cred = [pscredential]::new( $settings.login.username, $stringSecure )

    # Read static attribute
    [Emarsys]::allowNewFieldCreation

    # Create emarsys object
    $emarsys = [Emarsys]::new($cred,$settings.base)

    [uint64]$currentTimestamp = Get-Unixtime -inMilliseconds -timestamp $timestamp


    Created a list with Add-ContactList and got id 31000652 on 2024-03-25

    Get-ListCount

    Zweite Liste: 890495209


    New Authentication https://dev.emarsys.com/docs/emarsys-core-api-guides/branches/OAuth-2.0/b3c3a1eba8515-authentication-in-v3-api
    Your account owner can create new API Credentials and matching secret keys under Management > Security Settings

    Get the JWT
    curl -i -X POST --location https://auth.emarsys.net/oauth2/token \
    -H 'Authorization:Basic base64(clientId:clientsecret)' \
    -H 'Content-Type:application/x-www-form-urlencoded' \
    -H 'Accept:application/json' \
    -d 'grant_type=client_credentials' \

    Then first call
    curl --location 'https://api.emarsys.net/api/v3/settings' \
    -H 'Authorization: Bearer JWT'

    A single call to the Create Contacts endpoint can contain up to 1000 contacts, with a maximum payload size of 10 MB. You need to verify on your end that you send contact data in batches, where each call complies with these limits.

    Current Processes

    GET [0] "https://api.emarsys.net/api/v2/contactlist"                                https://dev.emarsys.com/docs/core-api-reference/axpotjvepqdla-list-contact-lists
    POST [0] "https://api.emarsys.net/api/v2/contactlist"                               https://dev.emarsys.com/docs/core-api-reference/enmevkj1fi016-create-a-contact-list
    GET [0] "https://api.emarsys.net/api/v2/field"                                      https://dev.emarsys.com/docs/core-api-reference/a0l7f9tviiuiv-list-available-fields
    PUT [0] "https://api.emarsys.net/api/v2/contact/?create_if_not_exists=0             https://dev.emarsys.com/docs/core-api-reference/g617t4kfs4y69-create-contact
    POST [0] "https://api.emarsys.net/api/v2/contactlist/1514342604/add                 https://dev.emarsys.com/docs/core-api-reference/e6v1un6ph06f3-add-contacts-to-a-contact-list
    GET [0] "https://api.emarsys.net/api/v2/contactlist"                                https://dev.emarsys.com/docs/core-api-reference/kvrstrtu2zohd-count-contacts-in-a-contact-list
    GET [0] "https://api.emarsys.net/api/v2/email/?status=1&fromdate=1925-09-25"        https://dev.emarsys.com/docs/core-api-reference/dvlvxbyt52gqi-list-email-campaigns
    GET [0] "https://api.emarsys.net/api/v2/email/?status=2&fromdate=1925-09-25"
    GET [0] "https://api.emarsys.net/api/v2/email/?status=4&fromdate=1925-09-25"
    POST [0] "https://api.emarsys.net/api/v2/email/15586704/copy                        https://dev.emarsys.com/docs/core-api-reference/vxro97zunmbo5-copy-an-email-campaign
    GET [0] "https://api.emarsys.net/api/v2/email/15594992"                             https://dev.emarsys.com/docs/core-api-reference/cikf60g6z8wkq-get-email-campaign-data
    POST [0] "https://api.emarsys.net/api/v2/email/15594992/patch                       https://dev.emarsys.com/docs/core-api-reference/5osux89c8np5a-update-an-email-campaign
    POST [0] "https://api.emarsys.net/api/v2/email/15594992/updatesource                https://dev.emarsys.com/docs/core-api-reference/83j2ovbqukcul-update-an-email-campaign-recipient-source
    POST [0] "https://api.emarsys.net/api/v2/email/15594992/launch                      https://dev.emarsys.com/docs/core-api-reference/vco94smya8mxm-launch-an-email-campaign

#>