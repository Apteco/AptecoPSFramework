


# Step 2. Encode the pair to Base64 string
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$( Get-SecureToPlaintext $settings.login.token ):"))
 
# Step 3. Form the header and add the Authorization attribute to it
$headers = @{ Authorization = "Basic $encodedCredentials" }




# For future better use of 
# https://www.optilyz.com/doc/api/
Authorization: Bearer {{api_key}}
