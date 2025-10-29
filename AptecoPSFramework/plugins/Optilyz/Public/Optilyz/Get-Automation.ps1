$url = "$( $settings.base )/v2/automations" 

$result = Invoke-RestMethod -uri $url -Headers $headers -Method Get -Verbose



$automations = @()
$result | where { $_.state -in $Script:settings.upload.automationStates } | foreach {

    # Load data
    $automation = $_
    #$campaign = $campaignDetails.elements.where({ $_.id -eq $mailing.campaignId })

    # Create mailing objects
    $automations += [OptilyzAutomation]@{automationId=$automation.'_id';automationName=$automation.name}

}