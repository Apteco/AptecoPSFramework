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

#>