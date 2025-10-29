$fields = Invoke-RestMethod -Verbose -Uri "$( $settings.base )/v1/dataMappingFields" -Method Get -Headers $headers -ContentType $contentType #-Body $bodyJson -TimeoutSec $maxTimeout
